#!/bin/bash
# shellcheck disable=SC2016  # crases são literais do JMESPath (--query), não substituição de comando
#
# deploy-com-rollback.sh — Gerencia deploys da BIA no ECS usando o short hash do commit Git.
#
# Uso:
#   ./deploy-com-rollback.sh deploy               build + push da imagem com a tag do commit atual e deploy
#   ./deploy-com-rollback.sh rollback <revisao>   faz deploy de uma revisão anterior da task definition
#   ./deploy-com-rollback.sh list                 lista as revisões da task definition com a imagem de cada uma
#   ./deploy-com-rollback.sh status               mostra a versão em execução e o estado do deploy
#
# Variáveis configuráveis (sobrescreva via ambiente se quiser o ambiente com ALB):
#   CLUSTER=cluster-bia-alb SERVICE=service-bia-alb ./deploy-com-rollback.sh deploy
#
# Defaults (ambiente sem ALB):
#   CLUSTER  = cluster-bia
#   SERVICE  = service-bia
#   REGION   = us-east-1
#   REPO     = bia-repo
#   CONTAINER= bia

set -euo pipefail

# ─── Configuração ────────────────────────────────────────────────────────────
REGION="${REGION:-us-east-1}"
CLUSTER="${CLUSTER:-cluster-bia}"
SERVICE="${SERVICE:-service-bia}"
CONTAINER="${CONTAINER:-bia}"
REPO="${REPO:-bia-repo}"

export AWS_DEFAULT_REGION="$REGION"

# ─── Funções auxiliares ───────────────────────────────────────────────────────

registry() {
  aws sts get-caller-identity --query Account --output text
  # retorna só o account id; o chamador monta a URL completa
}

ecr_base() {
  echo "$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$REGION.amazonaws.com"
}

task_def_ativa() {
  local td
  td=$(aws ecs describe-services \
    --cluster "$CLUSTER" \
    --services "$SERVICE" \
    --query 'services[0].taskDefinition' \
    --output text 2>&1)

  if [ -z "$td" ] || [ "$td" = "None" ]; then
    echo "!! Service '$SERVICE' não encontrado no cluster '$CLUSTER'." >&2
    echo "   Verifique as variáveis CLUSTER e SERVICE e se a infra está provisionada." >&2
    exit 1
  fi
  echo "$td"
}

familia_da_task_def() {
  # Extrai o nome da família a partir do ARN (ex: task-def-bia:5 → task-def-bia)
  local arn="$1"
  echo "${arn##*/}" | cut -d: -f1
}

imagem_da_revisao() {
  aws ecs describe-task-definition \
    --task-definition "$1" \
    --query "taskDefinition.containerDefinitions[?name=='$CONTAINER'].image | [0]" \
    --output text
}

# Clona a task definition atual trocando apenas a imagem e retorna o novo ARN.
registrar_nova_task_def() {
  local imagem="$1"
  local arquivo
  arquivo=$(mktemp)

  aws ecs describe-task-definition \
    --task-definition "$(task_def_ativa)" \
    --query taskDefinition \
    --output json \
    | jq \
        --arg img "$imagem" \
        --arg c   "$CONTAINER" '
          if any(.containerDefinitions[]; .name == $c)
          then .
          else error("container \($c) não encontrado na task definition")
          end
          | (.containerDefinitions[] | select(.name == $c) | .image) = $img
          | del(.taskDefinitionArn, .revision, .status, .requiresAttributes,
                .compatibilities, .registeredAt, .registeredBy, .deregisteredAt)
        ' > "$arquivo"

  aws ecs register-task-definition \
    --cli-input-json "file://$arquivo" \
    --query taskDefinition.taskDefinitionArn \
    --output text

  rm -f "$arquivo"
}

# Atualiza o service e acompanha o deploy até COMPLETED ou FAILED.
atualizar_service() {
  local task_def="$1"
  local deploy_id estado motivo

  echo ">> Atualizando $SERVICE para ${task_def##*/}"
  deploy_id=$(
    aws ecs update-service \
      --cluster "$CLUSTER" \
      --service  "$SERVICE" \
      --task-definition "$task_def" \
      --query 'service.deployments[?status==`PRIMARY`].id | [0]' \
      --output text
  )

  echo ">> Acompanhando deploy $deploy_id (Ctrl+C cancela o acompanhamento — o deploy continua)"
  while true; do
    read -r estado motivo < <(
      aws ecs describe-services \
        --cluster "$CLUSTER" \
        --services "$SERVICE" \
        --query "services[0].deployments[?id=='$deploy_id'] | [0].[rolloutState, rolloutStateReason]" \
        --output text
    )
    echo "   $(date +%H:%M:%S)  $estado"
    case "$estado" in
      COMPLETED)
        echo ">> Deploy concluído. ${task_def##*/} está no ar."
        return 0
        ;;
      FAILED)
        echo ">> Deploy FALHOU: $motivo"
        echo "   Se o circuit breaker com rollback automático estiver ligado, o ECS já está revertendo."
        echo "   Verifique com: $0 status"
        return 1
        ;;
      None|"")
        echo ">> O deploy saiu da lista (foi substituído por outro). Verifique com: $0 status"
        return 1
        ;;
    esac
    sleep 15
  done
}

# ─── Comandos ────────────────────────────────────────────────────────────────

cmd_deploy() {
  local raiz tag imagem base

  raiz=$(git rev-parse --show-toplevel)
  tag=$(git rev-parse --short=7 HEAD)

  if [ -n "$(git -C "$raiz" status --porcelain)" ]; then
    echo "!! Existem alterações não commitadas. A imagem será tagueada como $tag,"
    echo "   mas o conteúdo não bate exatamente com esse commit."
    read -r -p "   Continuar mesmo assim? [s/N] " ok
    [[ "$ok" == "s" || "$ok" == "S" ]] || { echo "Operação cancelada."; exit 1; }
  fi

  base=$(ecr_base)
  imagem="$base/$REPO:$tag"

  echo ">> Login no ECR ($base)"
  aws ecr get-login-password | docker login --username AWS --password-stdin "$base"

  echo ">> Build da imagem: $imagem"
  docker build -t "$imagem" "$raiz"

  echo ">> Push: $imagem"
  docker push "$imagem"

  echo ">> Registrando nova task definition"
  local nova_td
  nova_td=$(registrar_nova_task_def "$imagem")

  atualizar_service "$nova_td"
}

cmd_rollback() {
  local revisao="${1:-}"
  local familia atual rev_alvo

  if [ -z "$revisao" ]; then
    echo "!! Informe o número da revisão. Veja as disponíveis com: $0 list"
    exit 1
  fi

  atual=$(task_def_ativa)
  familia=$(familia_da_task_def "$atual")
  rev_alvo="$familia:$revisao"

  # Confirma que a revisão existe
  aws ecs describe-task-definition --task-definition "$rev_alvo" >/dev/null 2>&1 \
    || { echo "!! Revisão $rev_alvo não encontrada. Veja as disponíveis com: $0 list"; exit 1; }

  local imagem_alvo
  imagem_alvo=$(imagem_da_revisao "$rev_alvo")
  echo ">> Rollback para $rev_alvo (imagem: $imagem_alvo)"

  atualizar_service "$rev_alvo"
}

cmd_list() {
  local atual familia

  atual=$(task_def_ativa)
  familia=$(familia_da_task_def "$atual")
  local rev_ativa="${atual##*/}"   # ex: task-def-bia:5

  echo "Cluster : $CLUSTER"
  echo "Service : $SERVICE"
  echo "Família : $familia"
  echo "Ativa   : $rev_ativa"
  echo ""
  echo "Revisões disponíveis (mais recentes primeiro):"
  echo "──────────────────────────────────────────────────────────────────────"
  printf "%-6s  %-12s  %-60s\n" "REV" "STATUS" "IMAGEM"
  echo "──────────────────────────────────────────────────────────────────────"

  # Lista até 20 revisões (ACTIVE + a que está em uso, que pode ser INACTIVE após rollback)
  local arns
  arns=$(aws ecs list-task-definitions \
    --family-prefix "$familia" \
    --sort DESC \
    --query 'taskDefinitionArns[:20]' \
    --output text | tr '\t' '\n')

  while IFS= read -r arn; do
    [ -z "$arn" ] && continue
    local rev status imagem marker
    rev="${arn##*:}"
    status=$(aws ecs describe-task-definition \
      --task-definition "$arn" \
      --query 'taskDefinition.status' \
      --output text)
    imagem=$(imagem_da_revisao "$arn")
    marker=""
    [ "$arn" = "$atual" ] && marker=" ◀ ativa"
    printf "%-6s  %-12s  %-60s%s\n" "$rev" "$status" "$imagem" "$marker"
  done <<< "$arns"

  echo "──────────────────────────────────────────────────────────────────────"
  echo ""
  echo "Para fazer rollback: $0 rollback <REV>"
}

cmd_status() {
  local atual
  atual=$(task_def_ativa)

  echo "Cluster         : $CLUSTER"
  echo "Service         : $SERVICE"
  echo "Task definition : ${atual##*/}"
  echo "Imagem          : $(imagem_da_revisao "$atual")"
  echo ""

  echo "Circuit breaker:"
  aws ecs describe-services \
    --cluster "$CLUSTER" \
    --services "$SERVICE" \
    --query 'services[0].deploymentConfiguration.deploymentCircuitBreaker.[enable, rollback]' \
    --output text \
    | awk '{
        cb  = ($1 == "True" ? "ligado"    : "desligado")
        rbk = ($2 == "True" ? "ligado"    : "desligado")
        printf "  enable=%s  rollback=%s\n", cb, rbk
      }'

  echo ""
  echo "Deployments ativos:"
  aws ecs describe-services \
    --cluster "$CLUSTER" \
    --services "$SERVICE" \
    --query 'services[0].deployments[].{
               Status:status,
               Rollout:rolloutState,
               Revisao:taskDefinition,
               Rodando:runningCount,
               Desejado:desiredCount
             }' \
    --output table
}

# ─── Roteamento de comandos ───────────────────────────────────────────────────

case "${1:-}" in
  deploy)   cmd_deploy ;;
  rollback) cmd_rollback "${2:-}" ;;
  list)     cmd_list ;;
  status)   cmd_status ;;
  *)
    echo ""
    echo "Uso: $0 <comando> [args]"
    echo ""
    echo "Comandos:"
    echo "  deploy               Build + push da imagem (tag = short hash do commit) e deploy no ECS"
    echo "  rollback <revisao>   Deploy de uma revisão anterior da task definition"
    echo "  list                 Lista as revisões da task definition com a imagem de cada uma"
    echo "  status               Mostra a versão em execução e o estado do deploy"
    echo ""
    echo "Variáveis configuráveis (defaults: cluster-bia / service-bia):"
    echo "  CLUSTER, SERVICE, REGION, REPO, CONTAINER"
    echo ""
    echo "Exemplo (ambiente com ALB):"
    echo "  CLUSTER=cluster-bia-alb SERVICE=service-bia-alb $0 deploy"
    echo ""
    exit 1
    ;;
esac

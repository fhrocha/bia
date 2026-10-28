# Passo a passo — Túnel SSM até o ElastiCache (BIA, cenário 4)

Guia de acesso ao Valkey com **TLS ativo** via SSM Port Forwarding na instância `bia-dev`.

Pré-requisitos:
- AWS CLI v2 configurada no profile `formacaoaws`
- `session-manager-plugin` instalado (a sua máquina já tem 1.2.792.0)
- `redis-cli` nativo via Homebrew (`brew install redis`) — sem Docker
- EC2 `bia-dev` em execução
- Permissões SSM no usuário IAM (`AmazonSSMFullAccess`) para abrir o túnel

---

## Bloco único — copie e cole (terminal principal)

```bash
# 1) resolver instância + endpoint
INSTANCE_ID=$(aws ec2 describe-instances --profile formacaoaws --region us-east-1 --filters "Name=tag:Name,Values=bia-dev" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].InstanceId' --output text)
CACHE_HOST=$(aws elasticache describe-cache-clusters --profile formacaoaws --region us-east-1 --show-cache-node-info --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' --output text)
echo "instancia: $INSTANCE_ID | cache: $CACHE_HOST"
```

Esse bloco salva as duas variáveis. Cole o próximo em:

- **Terminal 1** → abre o túnel (fica preso; Ctrl+C encerra):

```bash
aws ssm start-session --profile formacaoaws --region us-east-1 --target $INSTANCE_ID --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters "{\"host\":[\"$CACHE_HOST\"],\"portNumber\":[\"6379\"],\"localPortNumber\":[\"6379\"]}"
```

Quando aparecer `Port Forwarding sessions started: 1`, o túnel está ativo em `127.0.0.1:6379`.

> O túnel é TCP transparente — o TLS fica de ponta a ponta com o ElastiCache,
> por isso o cliente abaixo usa `--tls`.

- **Terminal 2** → consulta os dados (com o túnel aberto):

```bash
RC="redis-cli -h 127.0.0.1 -p 6379 --tls"
$RC PING
$RC KEYS '*'
$RC GET 'tarefas:all'
$RC TTL 'tarefas:all'
$RC INFO server | head -20
```

Modo interativo:

```bash
redis-cli -h 127.0.0.1 -p 6379 --tls
```

> O `redis-cli` roda direto no Mac, no `127.0.0.1` onde o túnel SSM escuta
> (instale com `brew install redis`). Sem Docker, sem `host.docker.internal`.

---

## Explicação de cada passo

### 1. Instância `bia-dev`
A instância EC2 precisa estar `running` e com o SSM agent **Online**
(role `role-acesso-ssm`). Checagem:

```bash
aws ssm describe-instance-information --profile formacaoaws --region us-east-1 \
  --query "[?Name=='bia-dev'].[Name,InstanceId,PingStatus]" --output table
```

### 2. Endpoint do cache (via `describe-cache-clusters`)
Use o endpoint do **nó** (`bia-cache-0001-001.…`) e não o `clustercfg.…`:
o cliente Redis da BIA (ioredis classe padrão) não fala protocolo de cluster.
Com 1 shard, o endpoint do nó funciona sempre.

```bash
aws elasticache describe-cache-clusters --profile formacaoaws --region us-east-1 \
  --show-cache-node-info \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' --output text
```

> **Importante:** o `describe-replication-groups` pode retornar `None` para
> `NodeGroups[0]...ReadEndpoint` quando o cluster está com *cluster mode
> enabled* (resposta omite os endpoints dos nós). Por isso o comando confiável
> é o `describe-cache-clusters --show-cache-node-info`, como no bloco acima.

### 3. Túnel SSM
`AWS-StartPortForwardingSessionToRemoteHost` abre um túnel TCP transparente
de `127.0.0.1:6379` até `<host-do-no>:6379` via SSM agent da `bia-dev`.

### 4. Cliente com TLS
Como o cluster Valkey tem **transit encryption** ativa, todo cliente precisa
de `--tls` (redis-cli/valkey-cli) ou `tls: {}` (ioredis na BIA).

---

## Comandos úteis no redis-cli (modo interativo)

| Comando                | O que mostra                                       |
|------------------------|----------------------------------------------------|
| `PING`                 | conectividade (responde `PONG`)                    |
| `KEYS *`               | todas as chaves (ex: `tarefas:all`)                |
| `TYPE tarefas:all`     | tipo da chave (ex: `string`)                       |
| `GET tarefas:all`      | conteúdo (JSON das tarefas em cache da API)        |
| `TTL tarefas:all`      | segundos restantes (cache expira via `EX` TTL)     |
| `INFO server`          | versão, engine (Valkey), uptime                    |
| `INFO keyspace`        | número de chaves por database                      |
| `MONITOR`              | stream de comandos em tempo real (sair com Ctrl+C) |

---

## Modo alternativo — direto de dentro da `bia-dev` (sem túnel)

Terminal local:

```bash
aws ssm start-session --profile formacaoaws --region us-east-1 --target $INSTANCE_ID
```

Dentro da sessão SSM o acesso ao cache é pela rede interna da VPC (SG do cache
precisa permitir 6379 a partir do SG `bia-dev`):

```bash
# com redis-cli/valkey-cli disponível na instância, se instalado
redis-cli -h bia-cache-0001-001.bia-cache.uxjkay.use1.cache.amazonaws.com -p 6379 --tls
```

---

## Atalho automatizado (opcional)

O script `scripts/tunnel-elasticache.sh` automatiza a resolução e abertura do túnel:

```bash
./scripts/tunnel-elasticache.sh status   # valida EC2 + SSM + endpoint
./scripts/tunnel-elasticache.sh open     # abre o túnel (Ctrl+C fecha)
```

> Os comandos `cli`/`ver`/`ttl`/`keys`/`info`/`direct` do script fazem uso
> histórico de Docker; prefira os comandos diretos do Terminal 2 (redis-cli
> nativo em `127.0.0.1`) conforme este guia.

---

## Troubleshooting

| Problema                          | Causa provável                                       |
|-----------------------------------|------------------------------------------------------|
| `Invalid length for parameter Parameters.host[0]` | `CACHE_HOST` vazio — as variáveis foram resolvidas em outro terminal, ou veio `None` do `describe-replication-groups`; use `describe-cache-clusters --show-cache-node-info` no MESMO terminal do `start-session` |
| `PING` sem resposta               | SG do cache sem regra 6379 a partir do SG `bia-dev`  |
| `command not found: redis-cli`    | instale com `brew install redis` (ou `brew install valkey`) |
| `signing error` / sessão falha    | SSM agent não Online (EC2 recém-iniciada; aguarde)   |
| `AccessDeniedException … ssm:StartSession` | usuário IAM sem permissão — anexe `AmazonSSMFullAccess` |
| `ECONNREFUSED` no túnel           | túnel encerrado (Ctrl+C) — reabra e teste            |
| erro de TLS no redis-cli          | faltou `--tls` (o cache exige TLS)                   |
| endpoint `clustercfg.` não aceita | usar endpoint do nó (`...-0001-001.…`)               |

# n8n — Queue Mode na AWS

**Região:** `us-east-2` (Ohio)  
**VPC:** Default (zonas A e B)  
**Arquitetura:** ECS em cluster EC2 + ALB + RDS PostgreSQL + ElastiCache Valkey  
**Modo n8n:** Queue Mode (main/webhook + workers separados)

---

## Sumário

1. [Visão Geral da Arquitetura](#1-visão-geral-da-arquitetura)
2. [Ordem de Execução](#2-ordem-de-execução)
3. [Variáveis de Ambiente](#3-variáveis-de-ambiente)
4. [Etapa 1 — Fundação (paralelo)](#etapa-1--fundação-paralelo--mais-demorado)
   - [1.1 Certificate Manager (ACM)](#11--certificate-manager-acm)
   - [1.2 Security Groups](#12--security-groups)
   - [1.3 RDS PostgreSQL](#13--rds-postgresql)
   - [1.4 ElastiCache Valkey](#14--elasticache-valkey)
5. [Etapa 2 — IAM](#etapa-2--iam)
6. [Etapa 3 — ALB e Target Group](#etapa-3--alb-e-target-group)
7. [Etapa 4 — ECS Cluster, Launch Template e ASG](#etapa-4--ecs-cluster-launch-template-e-asg)
8. [Etapa 5 — SSM Parameter Store](#etapa-5--ssm-parameter-store)
9. [Etapa 6 — Task Definitions](#etapa-6--task-definitions)
10. [Etapa 7 — ECS Services](#etapa-7--ecs-services)
11. [Etapa 8 — Route 53](#etapa-8--route-53)
12. [Checklist de Execução](#checklist-de-execução)
13. [Troubleshooting](#troubleshooting)

---

## 1. Visão Geral da Arquitetura

```
User → Route 53 (n8n.acme.app.br)
     → ALB alb-n8n (listener 443 / certificado *.acme.app.br)
     → Target Group tg-n8n (instance, deregistration 30s)
     → ECS cluster-n8n (EC2 t4g.small, ASG 1 instância)
          ├── service-n8n-main (task-n8n-main)
          │     └── container n8n-main: webhook + scheduler
          │         EXECUTIONS_MODE=queue
          └── service-n8n-worker (task-n8n-worker)
                └── containers worker 1 e worker 2
                    EXECUTIONS_MODE=queue
          ↓                         ↓
   ElastiCache Valkey          RDS PostgreSQL
   valkey-n8n-sg               db-n8n-sg
   TLS ativado                 TLS ativado
   cache.t4g.micro             db.t4g.micro
```

### Fluxo Queue Mode (conforme documentação n8n)

1. O processo **main** recebe triggers (webhooks, timers) e gera o execution ID
2. Publica o execution ID no **Valkey/Redis** (fila Bull)
3. Um **worker** disponível consome a mensagem da fila
4. O worker busca os dados do workflow no **PostgreSQL**
5. Executa o workflow e salva o resultado no banco
6. Notifica o main via Redis que a execução foi concluída

### Conceito: Main vs Worker

| Processo | Responsabilidade |
|----------|-----------------|
| **main** | Recebe webhooks, gerencia timers/triggers, serve a UI, publica execution IDs na fila Redis |
| **worker** | Consome execution IDs da fila, busca workflow no banco, executa, salva resultado |

Ambos usam **a mesma imagem Docker** (`n8nio/n8n`), diferenciados pelo comando de inicialização:
- Main: sem argumento (padrão)
- Worker: argumento `worker`

> **CRÍTICO:** O `N8N_ENCRYPTION_KEY` deve ser **idêntico** em main e todos os workers. Sem isso, os workers não conseguem descriptografar as credenciais salvas no banco.

---

## 2. Ordem de Execução

Critério: **recursos que demoram mais para provisionar primeiro**, respeitando dependências.

```
┌─────────────────────────────────────────────────────────────┐
│ ETAPA 1 — PARALELO (iniciar PRIMEIRO — mais demorado)       │
│  1.1 Certificate Manager (ACM) + validação DNS              │
│  1.2 Security Groups (todos os 4)                           │
│  1.3 RDS PostgreSQL  ──────┐                                │
│  1.4 ElastiCache Valkey ───┼── ~10-15 min cada              │
└───────────────────────────┼─────────────────────────────────┘
                             │
┌──────────────────────────▼───────────────────────────────── ┐
│ ETAPA 2 — IAM Role + Instance Profile                       │
│  (pode rodar em paralelo com Etapa 1)                       │
└──────────────────────────┬──────────────────────────────────┘
                            │
┌──────────────────────────▼──────────────────────────────────┐
│ ETAPA 3 — Target Group + ALB                                │
│  (aguarda: ACM validado + SGs criados)                      │
└──────────────────────────┬──────────────────────────────────┘
                            │
┌──────────────────────────▼──────────────────────────────────┐
│ ETAPA 4 — ECS Cluster + Launch Template + ASG               │
│  (aguarda: IAM Role criada)                                 │
└──────────────────────────┬──────────────────────────────────┘
                            │
┌──────────────────────────▼──────────────────────────────────┐
│ ETAPA 5 — SSM Parameter Store                               │
│  (pode rodar em paralelo com Etapas 3 e 4)                  │
│  - Criar parâmetros SecureString para senhas e chaves       │
│  - Adicionar policy SSM na ecsTaskExecutionRole             │
└──────────────────────────┬──────────────────────────────────┘
                            │
┌──────────────────────────▼──────────────────────────────────┐
│ ETAPA 6 — Task Definitions (main + worker)                  │
│  (aguarda: endpoints RDS, Valkey e parâmetros SSM)          │
└──────────────────────────┬──────────────────────────────────┘
                            │
┌──────────────────────────▼──────────────────────────────────┐
│ ETAPA 7 — ECS Services (main + worker)                      │
│  (aguarda: tudo das etapas anteriores)                      │
└──────────────────────────┬──────────────────────────────────┘
                            │
┌──────────────────────────▼──────────────────────────────────┐
│ ETAPA 8 — Route 53 (registro DNS A alias → ALB)             │
│  (aguarda: ALB com DNS name disponível)                     │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Variáveis de Ambiente

Preencher conforme cada recurso for provisionado. Salvar como `n8n.env`.

```bash
# ─── BANCO DE DADOS — RDS PostgreSQL ─────────────────────────
# Preencher após Etapa 1.3
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=<endpoint-do-rds.us-east-2.rds.amazonaws.com>
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=<senha-definida-na-criacao-do-rds>
DB_POSTGRESDB_SSL_ENABLED=true
DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=false

# ─── FILA — ElastiCache Valkey ────────────────────────────────
# Preencher após Etapa 1.4
# PORTA: 6380 com TLS | 6379 sem TLS
QUEUE_BULL_REDIS_HOST=<endpoint-do-valkey.cache.amazonaws.com>
QUEUE_BULL_REDIS_PORT=6380
QUEUE_BULL_REDIS_TLS=true
QUEUE_BULL_REDIS_TIMEOUT_THRESHOLD=10000

# ─── CHAVE DE CRIPTOGRAFIA ────────────────────────────────────
# Gerar UMA VEZ: openssl rand -hex 32
# Usar A MESMA CHAVE em main e workers
N8N_ENCRYPTION_KEY=<gerar-com-openssl-rand-hex-32>

# ─── HOST E URL ───────────────────────────────────────────────
N8N_HOST=n8n.acme.app.br
N8N_PORT=5678
N8N_PROTOCOL=https
N8N_WEBHOOK_URL=https://n8n.acme.app.br
WEBHOOK_URL=https://n8n.acme.app.br

# ─── MODO E HEALTH CHECK ──────────────────────────────────────
EXECUTIONS_MODE=queue
QUEUE_HEALTH_CHECK_ACTIVE=true

# ─── TIMEZONE ─────────────────────────────────────────────────
GENERIC_TIMEZONE=America/Sao_Paulo
TZ=America/Sao_Paulo

# ─── REFERÊNCIA DE IDs AWS (preencher conforme provisiona) ────
ACM_CERTIFICATE_ARN=arn:aws:acm:us-east-2:<account-id>:certificate/<id>
VPC_ID=<vpc-id-default>
SUBNET_A_ID=<subnet-id-us-east-2a>
SUBNET_B_ID=<subnet-id-us-east-2b>
SG_ALB_ID=<sg-id-alb-n8n-sg>
SG_EC2_ID=<sg-id-ec2-n8n-sg>
SG_DB_ID=<sg-id-db-n8n-sg>
SG_VALKEY_ID=<sg-id-valkey-n8n-sg>
AMI_ARM64_ID=<ami-id>
```

**Comandos úteis:**

```bash
# Gerar chave de criptografia
openssl rand -hex 32

# Buscar AMI ARM64 Amazon Linux 2023
aws ssm get-parameter \
  --region us-east-2 \
  --name "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64" \
  --query "Parameter.Value" --output text

# Listar subnets da VPC default
aws ec2 describe-subnets \
  --region us-east-2 \
  --filters "Name=defaultForAz,Values=true" \
  --query "Subnets[*].{ID:SubnetId,AZ:AvailabilityZone}" \
  --output table
```

---

## Etapa 1 — Fundação (paralelo — mais demorado)

### 1.1 — Certificate Manager (ACM)

**Por que primeiro:** O ALB precisa do certificado para o listener HTTPS. A validação DNS pode levar até 30 min.

| Campo | Valor |
|-------|-------|
| Tipo | Wildcard |
| Domínio | `*.acme.app.br` |
| Validação | DNS |
| Região | `us-east-2` |

Após criar: copiar o registro CNAME fornecido pelo ACM e adicioná-lo no Route 53 (hosted zone `acme.app.br`). Aguardar status **Issued**.

---

### 1.2 — Security Groups

**Por que aqui:** RDS e ElastiCache precisam dos SGs para serem criados. SGs são instâneos.

> **Network Mode `bridge`:** O tráfego das tasks ECS sai pelo IP da EC2 host. Os SGs de banco e cache referenciam `ec2-n8n-sg`, não um SG de task.

#### Diagrama de tráfego

```
                   INTERNET
                       │
                  443 (80 → redirect)
                       │
                ┌──────┴──────┐
                │ alb-n8n-sg  │
                └──────┬──────┘
                       │ All TCP (portas dinâmicas bridge)
                ┌──────┴──────┐
                │ ec2-n8n-sg  │ ← EC2 t4g.small (ECS host)
                └──────┬──────┘
                  ┌────┴────┐
             5432 │         │ 6380 (TLS)
                  ▼         ▼
           ┌──────────┐ ┌───────────────┐
           │db-n8n-sg │ │valkey-n8n-sg  │
           └──────────┘ └───────────────┘
```

#### Ordem de criação (para permitir referência entre SGs)

**SG 1 — `alb-n8n-sg`** (ALB)

| Direção | Porta | Protocolo | Source | Descrição |
|---------|-------|-----------|--------|-----------|
| Inbound | 443 | TCP | 0.0.0.0/0 | acesso público HTTPS |
| Outbound | All | All | 0.0.0.0/0 | — |

> **Porta 80:** O redirect HTTP → HTTPS é feito pelo listener do ALB, não exige inbound 80 no Security Group. O ALB processa o redirect internamente antes de qualquer resposta ao cliente.

**SG 2 — `ec2-n8n-sg`** (EC2 do cluster ECS)

| Direção | Porta | Protocolo | Source | Descrição |
|---------|-------|-----------|--------|-----------|
| Inbound | All TCP (0-65535) | TCP | `alb-n8n-sg` | acesso vindo de alb-n8n-sg |
| Outbound | All | All | 0.0.0.0/0 | — |

> **Motivo All TCP:** ECS no modo `bridge` aloca portas dinâmicas no host (32768-65535). O ALB precisa alcançar essas portas efêmeras.

**SG 3 — `db-n8n-sg`** (RDS PostgreSQL)

| Direção | Porta | Protocolo | Source | Descrição |
|---------|-------|-----------|--------|-----------|
| Inbound | 5432 | TCP | `ec2-n8n-sg` | acesso vindo de ec2-n8n-sg |
| Outbound | All | All | 0.0.0.0/0 | — |

**SG 4 — `valkey-n8n-sg`** (ElastiCache Valkey)

| Direção | Porta | Protocolo | Source | Descrição |
|---------|-------|-----------|--------|-----------|
| Inbound | 6379 | TCP | `ec2-n8n-sg` | acesso vindo de ec2-n8n-sg |
| Inbound | 6380 | TCP | `ec2-n8n-sg` | acesso vindo de ec2-n8n-sg (TLS) |
| Outbound | All | All | 0.0.0.0/0 | — |

> Liberar ambas as portas (6379 e 6380) pois com TLS ativado o ElastiCache usa a **porta 6380**. Confirmar após criação do cluster.

---

### 1.3 — RDS PostgreSQL

**Por que aqui:** ~10-15 min para provisionar. Iniciar o quanto antes.

| Campo | Valor |
|-------|-------|
| DB Instance Identifier | `db-n8n` |
| Engine | PostgreSQL 16.x (latest) |
| Template | Production (ou Sandbox/Free tier) |
| Instance type | `db.t4g.micro` |
| Storage | gp3, 20 GiB, autoscaling desabilitado |
| Multi-AZ | Não (Single-AZ) |
| VPC | Default |
| Acesso público | Não |
| Security Group | `db-n8n-sg` (remover o default) |
| Database name | `n8n` |
| Username | `n8n` |
| Password | Definir e salvar em `n8n.env` |
| Backup | Desabilitado |
| TLS | Ativar (`rds.force_ssl=1`) |

Após disponível (~10-15 min): anotar o **Endpoint** → `DB_POSTGRESDB_HOST` em `n8n.env`.

---

### 1.4 — ElastiCache Valkey

**Por que aqui:** ~10-15 min para provisionar. Iniciar em paralelo com o RDS.

| Campo | Valor |
|-------|-------|
| Engine | Valkey |
| Deployment | Node-based cluster |
| Creation Method | Easy create |
| Configuration | Demo `cache.t4g.micro` (0.5 GiB) |
| Cluster name | `valkey-n8n` |
| VPC | Default |
| Subnet Group | Criar novo: `subnet-group-n8n-a-b` (subnets A e B) |
| Security Group | `valkey-n8n-sg` |
| **Criptografia em trânsito** | **ATIVAR (TLS)** |
| Criptografia em repouso | Opcional |

> **Atenção pós-criação:** O ElastiCache cria com o SG default. Após criar, acessar o cluster → Modify → alterar Security Group para `valkey-n8n-sg`.

Após disponível: anotar o **Endpoint** → `QUEUE_BULL_REDIS_HOST` e confirmar a **Porta** (6380 com TLS) em `n8n.env`.

---

## Etapa 2 — IAM

> Pode ser feito enquanto RDS/ElastiCache estão provisionando.

### 2.1 — IAM Role para EC2

| Campo | Valor |
|-------|-------|
| Nome | `role-ecs-n8n-ec2` |
| Trusted entity | AWS service → EC2 |
| Policies | `AmazonEC2ContainerServiceforEC2Role` + `AmazonSSMManagedInstanceCore` |
| Instance Profile | Criado automaticamente com mesmo nome |

- `AmazonEC2ContainerServiceforEC2Role`: permite o agente ECS registrar a instância no cluster
- `AmazonSSMManagedInstanceCore`: permite acesso via Session Manager (sem key pair)

---

## Etapa 3 — ALB e Target Group

> Aguardar: SGs criados (1.2) e ACM com status Issued (1.1).

### 3.1 — Target Group

| Campo | Valor |
|-------|-------|
| Nome | `tg-n8n` |
| Target type | Instance |
| Protocolo | HTTP |
| Porta | 5678 |
| VPC | Default |
| Health check path | `/healthz` |
| Health check interval | 30s |
| Healthy threshold | 2 |
| Unhealthy threshold | 3 |
| **Deregistration delay** | **30 segundos** |

> O n8n expõe `/healthz` quando `QUEUE_HEALTH_CHECK_ACTIVE=true`. Não adicionar targets manualmente — o ECS fará isso ao criar o service.

### 3.2 — Application Load Balancer

| Campo | Valor |
|-------|-------|
| Nome | `alb-n8n` |
| Scheme | Internet-facing |
| IP type | IPv4 |
| VPC | Default |
| Subnets | `us-east-2a` + `us-east-2b` |
| Security Group | `alb-n8n-sg` (remover o default) |

**Listeners:**

| Porta | Protocolo | Ação |
|-------|-----------|------|
| 80 | HTTP | Redirect → HTTPS 443 |
| 443 | HTTPS | Forward → `tg-n8n` (rule default) |

- Certificado HTTPS: `*.acme.app.br` (do ACM — Etapa 1.1)
- Aguardar estado **Active** e anotar o DNS Name do ALB

---

## Etapa 4 — ECS Cluster, Launch Template e ASG

> Aguardar: IAM Role criada (Etapa 2).

### 4.1 — ECS Cluster

| Campo | Valor |
|-------|-------|
| Nome | `cluster-n8n` |
| Infrastructure | Amazon EC2 instances |
| Provisioning model | On-demand |

### 4.2 — Launch Template

| Campo | Valor |
|-------|-------|
| Nome | `lt-n8n-ec2` |
| AMI | Amazon Linux 2023 ARM64 (buscar via SSM — ver comando abaixo) |
| Instance type | `t4g.small` |
| Key pair | `n8n-dev` (criar se não existir) |
| Security Group | `ec2-n8n-sg` |
| IAM Instance Profile | `role-ecs-n8n-ec2` |
| Root volume | 30 GiB gp3 |

**User Data** (registra a instância no cluster ECS):

```bash
#!/bin/bash
echo ECS_CLUSTER=cluster-n8n >> /etc/ecs/ecs.config
```

**Buscar AMI ARM64:**

```bash
aws ssm get-parameter \
  --region us-east-2 \
  --name "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64" \
  --query "Parameter.Value" --output text
```

### 4.3 — Auto Scaling Group

| Campo | Valor |
|-------|-------|
| Nome | `asg-n8n` |
| Launch Template | `lt-n8n-ec2` |
| VPC | Default |
| Subnets | `us-east-2a` (zona A — 1 instância conforme diagrama) |
| Capacidade desejada | 1 |
| Capacidade mínima | 1 |
| Capacidade máxima | 1 |
| Health check type | EC2 |
| IP público | Enabled |

> Se mais instâncias forem necessárias, **informar antes de alterar** a capacidade.

**Capacity Provider no ECS Cluster:**

| Campo | Valor |
|-------|-------|
| Nome | `cp-n8n-ec2` |
| Auto Scaling Group | `asg-n8n` |
| Managed Scaling | Enabled |
| Target capacity | 100% |
| Managed termination protection | Disabled |

---

## Etapa 5 — SSM Parameter Store

> Pode rodar em paralelo com as Etapas 3 e 4.

### 5.1 — Parâmetros SecureString

As variáveis sensíveis **não devem** ser armazenadas em texto plano na task definition. Usar o SSM Parameter Store com `SecureString` garante que os valores fiquem criptografados com KMS e nunca apareçam nos logs ou no JSON da task.

| Nome do Parâmetro | Tipo | Descrição |
|---|---|---|
| `/n8n/DB_POSTGRESDB_PASSWORD` | SecureString | Senha do banco PostgreSQL |
| `/n8n/N8N_ENCRYPTION_KEY` | SecureString | Chave de criptografia do n8n (idêntica em main e workers) |

**Criar via CLI:**

```bash
# Senha do banco
aws ssm put-parameter \
  --region us-east-2 \
  --name "/n8n/DB_POSTGRESDB_PASSWORD" \
  --type "SecureString" \
  --description "Senha do banco de dados PostgreSQL do n8n" \
  --value "<senha-definida-na-criacao-do-rds>"

# Chave de criptografia
aws ssm put-parameter \
  --region us-east-2 \
  --name "/n8n/N8N_ENCRYPTION_KEY" \
  --type "SecureString" \
  --description "Chave de criptografia do n8n - deve ser identica em main e workers" \
  --value "<gerar-com-openssl-rand-hex-32>"
```

### 5.2 — Policy na ecsTaskExecutionRole

Para que o agente ECS consiga injetar os parâmetros `SecureString` nos containers, a `ecsTaskExecutionRole` precisa de permissão para ler o SSM e descriptografar via KMS.

Adicionar a seguinte **inline policy** na role `ecsTaskExecutionRole` via console IAM (requer usuário com permissão `iam:PutRolePolicy`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ssm:GetParameters", "ssm:GetParameter"],
      "Resource": "arn:aws:ssm:us-east-2:<account-id>:parameter/n8n/*"
    },
    {
      "Effect": "Allow",
      "Action": ["kms:Decrypt"],
      "Resource": "arn:aws:kms:us-east-2:<account-id>:key/alias/aws/ssm"
    }
  ]
}
```

> **Nota:** A `AmazonECSTaskExecutionRolePolicy` padrão já inclui `ssm:GetParameters` para parâmetros `String`. Para `SecureString` é obrigatório adicionar o `kms:Decrypt`. Não há policy gerenciada pela AWS que cubra os dois juntos de forma direcionada.

---

## Etapa 6 — Task Definitions

> Aguardar: endpoints do RDS (1.3) e Valkey (1.4) para preencher as variáveis.

### 5.1 — Task Definition: `task-n8n-main`

**Configurações gerais:**

| Campo | Valor |
|-------|-------|
| Family | `task-n8n-main` |
| Launch Type | EC2 |
| Network Mode | `bridge` |
| Task CPU | — (não definir — modo EC2, não Fargate) |
| Task Memory | — (não definir — usar limites do container) |
| Task Execution Role | `ecsTaskExecutionRole` |

**Container `n8n-main`:**

| Campo | Valor |
|-------|-------|
| Image | `n8nio/n8n:latest` (multi-arch, baixa ARM64 automaticamente) |
| Memory Hard Limit | `650` MB |
| Memory Soft Limit | — |
| CPU Units | `0` (sem reserva rígida) |
| Port Mappings | Host: `0` (dinâmico) → Container: `5678` TCP |
| Command | — (processo main padrão) |
| Essential | `true` |

**Variáveis de ambiente do container `n8n-main`:**

```
EXECUTIONS_MODE=queue

DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=<endpoint-do-rds>
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_SSL_ENABLED=true
DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=false

QUEUE_BULL_REDIS_HOST=<endpoint-do-valkey>
QUEUE_BULL_REDIS_PORT=6380
QUEUE_BULL_REDIS_TLS=true
QUEUE_BULL_REDIS_TIMEOUT_THRESHOLD=10000

N8N_HOST=n8n.acme.app.br
N8N_PORT=5678
N8N_PROTOCOL=https
N8N_WEBHOOK_URL=https://n8n.acme.app.br
WEBHOOK_URL=https://n8n.acme.app.br

QUEUE_HEALTH_CHECK_ACTIVE=true

GENERIC_TIMEZONE=America/Sao_Paulo
TZ=America/Sao_Paulo
```

**Secrets do container `n8n-main` (injetados via SSM Parameter Store):**

```
DB_POSTGRESDB_PASSWORD  → arn:aws:ssm:us-east-2:<account-id>:parameter/n8n/DB_POSTGRESDB_PASSWORD
N8N_ENCRYPTION_KEY      → arn:aws:ssm:us-east-2:<account-id>:parameter/n8n/N8N_ENCRYPTION_KEY
```

> Os valores são injetados como variáveis de ambiente pelo agente ECS no momento do start do container. Nunca aparecem no JSON da task definition.

**Health check do container:**

```
Command: ["CMD-SHELL", "wget -qO- http://localhost:5678/healthz || exit 1"]
Interval: 30s | Timeout: 5s | Retries: 3 | Start period: 60s
```

---

### 5.2 — Task Definition: `task-n8n-worker`

**Configurações gerais:**

| Campo | Valor |
|-------|-------|
| Family | `task-n8n-worker` |
| Launch Type | EC2 |
| Network Mode | `bridge` |
| Task CPU | — |
| Task Memory | — |
| Task Execution Role | `ecsTaskExecutionRole` |

**Container `n8n-worker`:**

| Campo | Valor |
|-------|-------|
| Image | `n8nio/n8n:latest` |
| Memory Hard Limit | `650` MB |
| Memory Soft Limit | — |
| CPU Units | `0` |
| Port Mappings | — (workers não são expostos via ALB) |
| **Command** | **`worker`** |
| Essential | `true` |

> O campo `Command` com valor `worker` é o que diferencia o worker do main. Sem ele, o container sobe como mais um main.

**Variáveis de ambiente do container `n8n-worker`:**

```
EXECUTIONS_MODE=queue

DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=<endpoint-do-rds>
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_SSL_ENABLED=true
DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=false

QUEUE_BULL_REDIS_HOST=<endpoint-do-valkey>
QUEUE_BULL_REDIS_PORT=6380
QUEUE_BULL_REDIS_TLS=true
QUEUE_BULL_REDIS_TIMEOUT_THRESHOLD=10000

# Concorrência: quantos workflows em paralelo por worker (padrão 10, mínimo recomendado 5)
# N8N_CONCURRENCY_PRODUCTION=10

QUEUE_HEALTH_CHECK_ACTIVE=true

GENERIC_TIMEZONE=America/Sao_Paulo
TZ=America/Sao_Paulo
```

**Secrets do container `n8n-worker` (injetados via SSM Parameter Store):**

```
DB_POSTGRESDB_PASSWORD  → arn:aws:ssm:us-east-2:<account-id>:parameter/n8n/DB_POSTGRESDB_PASSWORD
N8N_ENCRYPTION_KEY      → arn:aws:ssm:us-east-2:<account-id>:parameter/n8n/N8N_ENCRYPTION_KEY
```

> **CRÍTICO:** O `N8N_ENCRYPTION_KEY` deve ser **idêntico** ao do main. Como ambos referenciam o mesmo parâmetro SSM `/n8n/N8N_ENCRYPTION_KEY`, isso é garantido automaticamente.

**Health check do container:**

```
Command: ["CMD-SHELL", "wget -qO- http://localhost:5678/healthz || exit 1"]
Interval: 30s | Timeout: 5s | Retries: 3 | Start period: 60s
```

---

### Comparativo Main vs Worker

| Aspecto | Main | Worker |
|---------|------|--------|
| Command | — (padrão) | `worker` |
| Porta 5678 exposta ao ALB | Sim | Não |
| Recebe webhooks | Sim | Não |
| Gerencia timers/triggers | Sim | Não |
| Executa workflows | Não (apenas enfileira) | Sim |
| Acessa Redis | Sim (publica) | Sim (consome) |
| Acessa PostgreSQL | Sim | Sim |
| `N8N_ENCRYPTION_KEY` | Definir aqui | **Mesma do main** |

---

## Etapa 7 — ECS Services

> Aguardar: task definitions (6), target group (3.1), cluster com instância EC2 disponível (4).

### 6.1 — Service Main: `service-n8n-main`

| Campo | Valor |
|-------|-------|
| Nome | `service-n8n-main` |
| Cluster | `cluster-n8n` |
| Task Definition | `task-n8n-main` (latest) |
| Launch Type | EC2 |
| Desired tasks | `1` |
| Deployment type | Rolling Update |
| **Minimum healthy %** | **0** |
| **Maximum %** | **100** |
| **AZ Rebalancing** | **DISABLED** |
| Load Balancer | `alb-n8n` |
| Container | `n8n-main:5678` |
| Target Group | `tg-n8n` |

> `0,100`: necessário para parar a task antes de subir a nova quando há apenas 1 instância EC2.

### 6.2 — Service Worker: `service-n8n-worker`

| Campo | Valor |
|-------|-------|
| Nome | `service-n8n-worker` |
| Cluster | `cluster-n8n` |
| Task Definition | `task-n8n-worker` (latest) |
| Launch Type | EC2 |
| Desired tasks | `2` |
| Deployment type | Rolling Update |
| **Minimum healthy %** | **0** |
| **Maximum %** | **100** |
| **AZ Rebalancing** | **DISABLED** |
| Load Balancer | Nenhum (workers não são expostos via ALB) |

---

## Etapa 8 — Route 53

> Aguardar: ALB com DNS name disponível (Etapa 3.2).

| Campo | Valor |
|-------|-------|
| Hosted Zone | `acme.app.br` |
| Record name | `n8n` |
| Record type | A (Alias) |
| Alias target | DNS do ALB (`alb-n8n-xxxx.us-east-2.elb.amazonaws.com`) |
| Routing policy | Simple |

---

## Checklist de Execução

### Pré-requisitos

- [ ] Gerar chave de criptografia: `openssl rand -hex 32` → salvar em `n8n.env`
- [ ] Confirmar que o domínio `acme.app.br` está acessível no Route 53
- [ ] Criar arquivo `n8n.env`

### Etapa 1.1 — ACM

- [ ] Solicitar certificado wildcard `*.acme.app.br` na região `us-east-2`
- [ ] Adicionar CNAME de validação no Route 53
- [ ] Aguardar status **Issued**
- [ ] Anotar ARN → `ACM_CERTIFICATE_ARN` em `n8n.env`

### Etapa 1.2 — Security Groups

- [ ] Criar `alb-n8n-sg` com inbound **443 apenas** de 0.0.0.0/0 (redirect HTTP→HTTPS é feito pelo listener do ALB)
- [ ] Criar `ec2-n8n-sg` com inbound All TCP de `alb-n8n-sg`
- [ ] Criar `db-n8n-sg` com inbound 5432 de `ec2-n8n-sg`
- [ ] Criar `valkey-n8n-sg` com inbound 6379 e 6380 de `ec2-n8n-sg`
- [ ] Anotar IDs dos 4 SGs em `n8n.env`

### Etapa 1.3 — RDS PostgreSQL

- [ ] Criar RDS PostgreSQL `db-n8n` (db.t4g.micro, gp3 20 GiB, Single-AZ)
- [ ] SG: `db-n8n-sg` | DB name: `n8n` | User: `n8n` | TLS: on | Backup: off
- [ ] Aguardar status **Available** (~10-15 min)
- [ ] Anotar Endpoint → `DB_POSTGRESDB_HOST` em `n8n.env`

### Etapa 1.4 — ElastiCache Valkey

- [ ] Criar cluster Valkey `valkey-n8n` (cache.t4g.micro, TLS ativado)
- [ ] Subnet Group: `subnet-group-n8n-a-b` (zonas A e B)
- [ ] Aguardar criação completar (~10-15 min)
- [ ] Pós-criação: alterar SG para `valkey-n8n-sg`
- [ ] Anotar Endpoint e Porta (6380 TLS) em `n8n.env`

### Etapa 2 — IAM

- [ ] Criar role `role-ecs-n8n-ec2` com policies `AmazonEC2ContainerServiceforEC2Role` e `AmazonSSMManagedInstanceCore`

### Etapa 3 — Target Group e ALB

- [ ] Criar Target Group `tg-n8n` (instance, HTTP:5678, health `/healthz`, deregistration 30s)
- [ ] Criar ALB `alb-n8n` (subnets A+B, SG `alb-n8n-sg`, listener 80→**redirect HTTPS 443**, listener 443→`tg-n8n`)
- [ ] Aguardar estado **Active** e anotar DNS Name do ALB

### Etapa 4 — ECS Cluster + ASG

- [ ] Buscar AMI ARM64 via SSM Parameter Store
- [ ] Criar ECS Cluster `cluster-n8n` com EC2 `t4g.small`, IAM Profile `role-ecs-n8n-ec2`, SG `ec2-n8n-sg`
- [ ] User Data: `echo ECS_CLUSTER=cluster-n8n >> /etc/ecs/ecs.config`
- [ ] ASG `asg-n8n`: desired 1, min 1, max 1, subnet `us-east-2a`
- [ ] Aguardar instância EC2 registrada no cluster como ACTIVE

### Etapa 5 — SSM Parameter Store

- [ ] Criar parâmetro `SecureString` `/n8n/DB_POSTGRESDB_PASSWORD` com a senha do RDS
- [ ] Criar parâmetro `SecureString` `/n8n/N8N_ENCRYPTION_KEY` com a chave gerada por `openssl rand -hex 32`
- [ ] Adicionar inline policy `n8n-ssm-secrets` na `ecsTaskExecutionRole` (permissões `ssm:GetParameters` + `kms:Decrypt` para `/n8n/*`)

### Etapa 6 — Task Definitions

- [ ] Criar `task-n8n-main`: EC2, bridge, container `n8n-main`, hard limit 500MB, porta 5678, variáveis de ambiente sem senhas, secrets apontando para SSM
- [ ] Criar `task-n8n-worker`: EC2, bridge, container `n8n-worker`, hard limit 500MB, **command `worker`**, secrets apontando para SSM

### Etapa 7 — ECS Services

- [ ] Criar `service-n8n-main`: desired 1, min 0%, max 100%, AZ rebalancing DISABLED, ALB `alb-n8n`, TG `tg-n8n`, **healthCheckGracePeriodSeconds 120**
- [ ] Aguardar task RUNNING e health check Healthy no Target Group
- [ ] Criar `service-n8n-worker`: desired 2, min 0%, max 100%, AZ rebalancing DISABLED, sem ALB
- [ ] Aguardar 2 tasks RUNNING

### Etapa 8 — Route 53

- [ ] Criar registro A alias `n8n.acme.app.br` → ALB `alb-n8n`

### Validação Final

- [ ] Acessar `https://n8n.acme.app.br` e completar o setup inicial
- [ ] Criar e executar um workflow simples — confirmar que o worker processa
- [ ] Verificar logs do `service-n8n-main` no CloudWatch
- [ ] Verificar logs do `service-n8n-worker` no CloudWatch
- [ ] Testar webhook via `https://n8n.acme.app.br/webhook/teste`

---

## Troubleshooting

| Problema | Possível Causa | Ação |
|----------|---------------|------|
| Task não inicia / OOM | EC2 t4g.small (2 GiB) com 3 tasks pesadas | Iniciar com 1 worker, depois escalar. Ver nota de capacidade abaixo |
| Health check failing | n8n ainda inicializando | Aguardar 60s (start period configurado) |
| Workers não processam | `N8N_ENCRYPTION_KEY` diferente | Confirmar que a chave é idêntica em main e workers |
| Não conecta ao Valkey | Porta errada ou TLS | Confirmar porta 6380 com TLS; verificar `valkey-n8n-sg` |
| Não conecta ao RDS | SG incorreto | Confirmar que `ec2-n8n-sg` é source em `db-n8n-sg` na porta 5432 |
| Certificado inválido | ACM não validado | Verificar se CNAME foi adicionado corretamente no Route 53 |
| ALB retorna 502 | Task ainda não registrada | Aguardar ECS registrar a task no target group |
| Workers sobem como main | Command não definido | Confirmar campo `Command = worker` na task definition |

### Nota sobre Capacidade da EC2

A `t4g.small` tem **2 GiB de RAM**. Com as 3 tasks:

| Task | Hard Limit |
|------|-----------|
| n8n-main (×1) | 650 MB |
| n8n-worker (×2) | 650 MB × 2 = 1.300 MB |
| SO + agente ECS | ~300 MB |
| **Total estimado** | **~2.250 MB** |

A margem é apertada. Recomendação: iniciar os testes com **desired count = 1** no `service-n8n-worker`. Aumentar para 2 após validar a estabilidade, ou migrar para `t4g.medium` (4 GiB) para conforto.

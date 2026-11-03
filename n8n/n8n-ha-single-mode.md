# Plano de Deploy — n8n na AWS (Single Mode)

**Região:** us-east-2 (Ohio)  
**Conta:** 600579993826  
**Perfil AWS:** n8n  
**Domínio:** n8n-bia.acme.app.br  
**Data do planejamento:** 2026-11-03  

---

## Visão Geral da Arquitetura

```
User → Route 53 (n8n-bia.acme.app.br)
     → ALB n8n-alb (HTTPS 443, sg-n8n-alb)
     → Target Group tg-n8n (deregistration delay 30s)
     → ECS Service service-bia-n8n (bridge mode)
         → Task task-bia-n8n (n8nio/n8n:stable, soft limit 650MB)
             → RDS n8n-db (PostgreSQL, sg-n8n-db, TLS enabled)
```

- **VPC:** Default (zonas us-east-2a e us-east-2b)
- **Cluster ECS:** cluster-n8n — EC2 t3.micro via ASG (1 instância)
- **Network mode:** bridge (EC2, sem awsvpc)
- **Imagem:** `n8nio/n8n:stable` (versão 2.46.4 — produção)

---

## Recursos a Provisionar

### 1. Security Groups

#### sg-n8n-alb
- **Finalidade:** Application Load Balancer
- **Inbound:**
  - Porta 443 — TCP — 0.0.0.0/0 — "acesso público HTTPS"
  - Porta 80 — TCP — 0.0.0.0/0 — "acesso público HTTP" *(opcional, para redirect)*
- **Outbound:** 0.0.0.0/0

#### sg-n8n-ec2
- **Finalidade:** Instâncias EC2 do cluster ECS
- **Inbound:**
  - All TCP — sg-n8n-alb — "acesso vindo de sg-n8n-alb"
- **Outbound:** 0.0.0.0/0

#### sg-n8n-db
- **Finalidade:** RDS PostgreSQL
- **Inbound:**
  - Porta 5432 — TCP — sg-n8n-ec2 — "acesso vindo de sg-n8n-ec2"
- **Outbound:** 0.0.0.0/0

---

### 2. RDS PostgreSQL

| Parâmetro | Valor |
|---|---|
| Identificador | `n8n-db` |
| Engine | PostgreSQL |
| Template | Free tier / Sandbox |
| Instância | `db.t4g.micro` |
| Storage | gp3, 20 GiB |
| Multi-AZ | Não (Single-AZ) |
| Acesso público | Não |
| VPC | Default |
| Security Group | `sg-n8n-db` |
| Database name | `n8n` |
| Username | `n8n` |
| Senha | `N8nDb#2026!Aws` |
| Backup | Desabilitado |
| TLS | Habilitado (`DB_POSTGRESDB_SSL_ENABLED=true`) |
| Certificado | `rds-ca-rsa2048-g1` (padrão AWS) — sem validação de CA (`REJECT_UNAUTHORIZED=false`) |

> **Senha salva em:** `n8n/.env`

---

### 3. Certificado ACM

| Parâmetro | Valor |
|---|---|
| Domínio | `*.acme.app.br` |
| Região | `us-east-2` |
| Método de validação | DNS (via Route 53) |
| Hosted Zone | `acme.app.br` (já existe) |

> **Atenção:** O listener HTTPS do ALB só pode ser criado após o certificado estar com status **Issued**.
> A validação DNS via Route 53 costuma levar de 1 a 5 minutos.

---

### 4. Application Load Balancer

| Parâmetro | Valor |
|---|---|
| Nome | `n8n-alb` |
| Tipo | Application (ALB) |
| Scheme | Internet-facing |
| VPC | Default |
| Subnets | us-east-2a + us-east-2b (subnets default) |
| Security Group | `sg-n8n-alb` |

#### Listener
| Parâmetro | Valor |
|---|---|
| Porta | 443 |
| Protocolo | HTTPS |
| Certificado | `*.acme.app.br` (ACM) |
| Default action | Forward → `tg-n8n` |

---

### 5. Target Group

| Parâmetro | Valor |
|---|---|
| Nome | `tg-n8n` |
| Tipo | `instance` |
| Protocolo | HTTP |
| Porta | 5678 |
| VPC | Default |
| Deregistration delay | 30 segundos |
| Health check path | `/healthz` |
| Health check protocolo | HTTP |

---

### 6. ECS — Cluster + ASG + Launch Template

#### Cluster
| Parâmetro | Valor |
|---|---|
| Nome | `cluster-n8n` |
| Tipo | EC2 |

#### Launch Template
| Parâmetro | Valor |
|---|---|
| AMI | ECS-Optimized Amazon Linux 2023 (us-east-2) |
| Tipo de instância | `t3.micro` |
| Security Group | `sg-n8n-ec2` |
| IAM Instance Profile | `role-acesso-ssm` |
| User data | Script de registro no cluster `cluster-n8n` |

#### Auto Scaling Group
| Parâmetro | Valor |
|---|---|
| Min | 1 |
| Max | 1 |
| Desired | 1 |
| Zona | us-east-2a (subnet default) |

---

### 7. ECS — Task Definition

| Parâmetro | Valor |
|---|---|
| Nome | `task-bia-n8n` |
| Launch type | EC2 |
| Network mode | `bridge` |
| Imagem | `n8nio/n8n:stable` |
| Container port | 5678 |
| Host port | 0 (dinâmico — ECS atribui porta aleatória) |
| Memory hard limit | 800 MB |
| Memory soft limit | 650 MB |
| CPU | 1 vCPU (1024 units) |

#### Variáveis de ambiente (injetadas via task definition)
Carregadas do arquivo `n8n/.env`:

```
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=<endpoint do RDS n8n-db>
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=N8nDb#2026!Aws
DB_POSTGRESDB_SSL_ENABLED=true
DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=false
N8N_HOST=n8n-bia.acme.app.br
N8N_PORT=5678
N8N_PROTOCOL=https
N8N_EDITOR_BASE_URL=https://n8n-bia.acme.app.br
WEBHOOK_URL=https://n8n-bia.acme.app.br/
N8N_PROXY_HOPS=1
N8N_ENCRYPTION_KEY=<chave aleatória 32 chars>
```

> **N8N_PROXY_HOPS=1** — obrigatório quando n8n está atrás de um ALB; garante que o IP real do cliente seja reconhecido corretamente.  
> **N8N_ENCRYPTION_KEY** — deve ser definida e mantida fixa; se o container for recriado sem essa chave, todas as credenciais salvas no n8n são perdidas.

---

### 8. ECS — Service

| Parâmetro | Valor |
|---|---|
| Nome | `service-bia-n8n` |
| Cluster | `cluster-n8n` |
| Task definition | `task-bia-n8n` |
| Desired count | 1 |
| Launch type | EC2 |
| Deployment type | Rolling Update |
| Minimum healthy percent | 0% |
| Maximum percent | 100% |
| AZ Rebalancing | Desativado |
| Load balancer | ALB `n8n-alb` |
| Target group | `tg-n8n` |
| Container | `task-bia-n8n` porta 5678 |

---

### 9. Arquivo `n8n/.env`

Localização: `/bia/n8n/.env`

```env
# Banco de dados
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=ENDPOINT_RDS
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=N8nDb#2026!Aws
DB_POSTGRESDB_SSL_ENABLED=true
DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=false

# Deployment
N8N_HOST=n8n-bia.acme.app.br
N8N_PORT=5678
N8N_PROTOCOL=https
N8N_EDITOR_BASE_URL=https://n8n-bia.acme.app.br
WEBHOOK_URL=https://n8n-bia.acme.app.br/
N8N_PROXY_HOPS=1

# Segurança
N8N_ENCRYPTION_KEY=GERAR_CHAVE_32_CHARS
```

> `ENDPOINT_RDS` e `N8N_ENCRYPTION_KEY` serão preenchidos durante a implementação.

---

### 10. Route 53

| Parâmetro | Valor |
|---|---|
| Hosted Zone | `acme.app.br` |
| Record name | `n8n-bia` |
| Tipo | A — Alias |
| Alias target | DNS name do ALB `n8n-alb` |

---

## Recursos Provisionados

> Registros dos componentes criados durante a implementação em 2026-11-03.

### VPC

| Recurso | ID |
|---|---|
| VPC Default | `vpc-0c8a1ecba7f28b60d` |
| Subnet us-east-2a | `subnet-0c2bbc5f46eeb2eb6` |
| Subnet us-east-2b | `subnet-0b8ac41495b453459` |

### Security Groups

> Nota: A AWS não permite nomes de Security Group iniciando com `sg-`, portanto os grupos foram criados sem esse prefixo.

| Nome | ID | Finalidade |
|---|---|---|
| `n8n-alb` | `sg-0cbf8ff2876de50ea` | ALB |
| `n8n-ec2` | `sg-0602e05ef5b9cb34e` | EC2 do cluster ECS |
| `n8n-db` | `sg-0cdaa426c986859ca` | RDS PostgreSQL |

### RDS PostgreSQL

| Parâmetro | Valor |
|---|---|
| Identificador | `n8n-db` |
| ARN | `arn:aws:rds:us-east-2:600579993826:db:n8n-db` |
| Engine | PostgreSQL 17.11 |
| Instância | `db.t4g.micro` |
| Endpoint | `n8n-db.cviswcg8idvc.us-east-2.rds.amazonaws.com` |
| Status | `available` |
| Certificado CA | `rds-ca-rsa2048-g1` |

### Certificado ACM

| Parâmetro | Valor |
|---|---|
| Domínio | `*.acme.app.br` |
| ARN | `arn:aws:acm:us-east-2:600579993826:certificate/7a78ed7e-a696-4b03-9820-7c5c22066728` |
| Status | `PENDING_VALIDATION` *(aguardando conclusão da transferência DNS ~1h15m)* |
| CNAME validação | `_0c40c40ca7c3e8f52c148824d0ed1f76.acme.app.br` → `_e8b5d180cd41fd285cc822f07b4ec00c.jkddzztszm.acm-validations.aws.` |

### Application Load Balancer

| Parâmetro | Valor |
|---|---|
| Nome | `n8n-alb` |
| ARN | `arn:aws:elasticloadbalancing:us-east-2:600579993826:loadbalancer/app/n8n-alb/13172bdeb496c4b1` |
| DNS | `n8n-alb-1158221505.us-east-2.elb.amazonaws.com` |
| Hosted Zone ID | `Z3AADJGX6KTTL2` |
| Scheme | `internet-facing` |
| Subnets | `us-east-2a`, `us-east-2b` |

### Target Group

| Parâmetro | Valor |
|---|---|
| Nome | `tg-n8n` |
| ARN | `arn:aws:elasticloadbalancing:us-east-2:600579993826:targetgroup/tg-n8n/b946b2dc64bdf4a1` |
| Tipo | `instance` |
| Porta | `5678` |
| Deregistration delay | `30s` |
| Health check path | `/healthz` |

### ECS — Cluster, Launch Template, ASG e EC2

| Recurso | Valor |
|---|---|
| Cluster | `cluster-n8n` — `arn:aws:ecs:us-east-2:600579993826:cluster/cluster-n8n` |
| AMI ECS-Optimized | `ami-030831d5502ebf96d` (Amazon Linux 2023) |
| Launch Template | `lt-cluster-n8n` — `lt-056e7d4944688950b` |
| IAM Instance Profile | `ecsInstanceRole` |
| ASG | `asg-cluster-n8n` (min=1, max=1, desired=1) — zona `us-east-2a` |
| EC2 Instance | `i-0f7efccfb63211257` — `t3.micro` — `running` |

### ECS — Task Definition

| Parâmetro | Valor |
|---|---|
| Nome | `task-bia-n8n:1` |
| ARN | `arn:aws:ecs:us-east-2:600579993826:task-definition/task-bia-n8n:1` |
| Network mode | `bridge` |
| Imagem | `n8nio/n8n:stable` |
| Memory hard | `800 MB` |
| Memory soft | `650 MB` |
| CPU | `1024 units` |
| Container port | `5678` / host port `0` (dinâmico) |

### ECS — Service

| Parâmetro | Valor |
|---|---|
| Nome | `service-bia-n8n` |
| ARN | `arn:aws:ecs:us-east-2:600579993826:service/cluster-n8n/service-bia-n8n` |
| Task definition | `task-bia-n8n:1` |
| Desired count | `1` |
| Min healthy % | `0%` |
| Max % | `100%` |
| AZ Rebalancing | `DISABLED` |
| Load balancer | ⚠️ *Não associado ainda — aguarda listener HTTPS (passo 5). Service precisará ser recriado com LB após o listener ser criado.* |

### Route 53

| Parâmetro | Valor |
|---|---|
| Hosted Zone | `acme.app.br` — `Z03773583SL3DJ9VMWZ2H` |
| Registro | `n8n-bia.acme.app.br` — A Alias |
| Alias target | `n8n-alb-1158221505.us-east-2.elb.amazonaws.com` |
| CNAME validação ACM | `_0c40c40ca7c3e8f52c148824d0ed1f76.acme.app.br` (criado) |

### Arquivo `n8n/.env` (atualizado)

```env
# Banco de dados
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=n8n-db.cviswcg8idvc.us-east-2.rds.amazonaws.com
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=N8nDb#2026!Aws
DB_POSTGRESDB_SSL_ENABLED=true
DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=false

# Deployment
N8N_HOST=n8n-bia.acme.app.br
N8N_PORT=5678
N8N_PROTOCOL=https
N8N_EDITOR_BASE_URL=https://n8n-bia.acme.app.br
WEBHOOK_URL=https://n8n-bia.acme.app.br/
N8N_PROXY_HOPS=1

# Segurança
N8N_ENCRYPTION_KEY=d2d861581164abc0b7cbb3f70993745f
```

### Pendente — Aguardando conclusão da transferência DNS (~1h15m)

> Service ECS e instância EC2 removidos temporariamente para evitar custo enquanto aguarda o certificado ACM.
> ASG `asg-cluster-n8n` configurado com min=0, desired=0.

| # | Ação | Condição |
|---|---|---|
| 1 | Aumentar ASG `asg-cluster-n8n` para min=1, desired=1 | Ao retomar |
| 2 | Criar Listener HTTPS 443 no ALB com certificado ACM | Aguarda certificado com status **Issued** |
| 3 | Recriar `service-bia-n8n` com load balancer associado ao `tg-n8n` | Após listener criado |

---

## Ordem de Implementação

| # | Recurso | Pré-requisito | Observação |
|---|---|---|---|
| 1 | Security Groups (`sg-n8n-alb`, `sg-n8n-ec2`, `sg-n8n-db`) | VPC Default | Base para todos os recursos |
| 2 | RDS PostgreSQL (`n8n-db`) | `sg-n8n-db` | Gera o endpoint que vai para o `.env` |
| 3 | Certificado ACM (`*.acme.app.br`) | Hosted Zone `acme.app.br` | Validação DNS — aguardar status **Issued** |
| 4 | ALB (`n8n-alb`) + Target Group (`tg-n8n`) | `sg-n8n-alb`, subnets | Criar ALB sem listener HTTPS ainda |
| 5 | Listener HTTPS 443 no ALB | Certificado com status **Issued** | Associar certificado ACM + regra → `tg-n8n` |
| 6 | Launch Template + ASG + Cluster ECS (`cluster-n8n`) | `sg-n8n-ec2`, AMI ECS | 1 instância t3.micro na zona a |
| 7 | Atualizar `n8n/.env` | Endpoint do RDS (passo 2) | Preencher `ENDPOINT_RDS` e gerar `N8N_ENCRYPTION_KEY` |
| 8 | Task Definition (`task-bia-n8n`) | `.env` atualizado | Bridge mode, 650MB soft limit, imagem `n8nio/n8n:stable` |
| 9 | Service ECS (`service-bia-n8n`) | Cluster com EC2 disponível, Target Group | Rolling 0/100, AZ Rebalancing off |
| 10 | Route 53 — `n8n-bia.acme.app.br` | ALB provisionado (passo 4) | Alias A record → DNS do ALB |

---

## Dependências Críticas

- **Passo 5 depende do passo 3:** listener HTTPS só pode ser criado com certificado **Issued**
- **Passo 7 depende do passo 2:** endpoint do RDS precisa existir para preencher o `.env`
- **Passo 9 depende do passo 6:** service ECS precisa de ao menos 1 EC2 registrado no cluster para fazer o deploy da task
- **N8N_ENCRYPTION_KEY:** gerar uma vez, salvar no `.env` e nunca alterar após o primeiro boot — trocar a chave invalida todas as credenciais salvas no n8n

---

## Permissões IAM — Usuário `n8n`

O usuário `n8n` (conta 600579993826) não possui permissões granulares.
As políticas gerenciadas pela AWS abaixo devem ser associadas ao usuário para execução completa do plano.

| # | Política Gerenciada | Cobre |
|---|---|---|
| 1 | `AmazonVPCFullAccess` | Security Groups, subnets, VPC |
| 2 | `AmazonRDSFullAccess` | RDS — criar, configurar, descrever |
| 3 | `AWSCertificateManagerFullAccess` | Criar e validar certificado ACM |
| 4 | `ElasticLoadBalancingFullAccess` | ALB, Target Group, Listener |
| 5 | `AmazonEC2FullAccess` | Launch Template, ASG, instâncias EC2 |
| 6 | `AmazonECS_FullAccess` | Cluster, Task Definition, Service |
| 7 | `AmazonSSMFullAccess` | Parameter Store (AMI ECS-optimized) |
| 8 | `AmazonRoute53FullAccess` | Registros DNS na hosted zone `acme.app.br` |

---

## Referências

- [Documentação oficial n8n — Hosting](https://docs.n8n.io/hosting/)
- [Documentação oficial n8n — Deploy to AWS](https://docs.n8n.io/deploy/host-n8n/install-options/use-a-cloud-provider/deploy-to-aws)
- [Variáveis de ambiente — Database](https://docs.n8n.io/deploy/host-n8n/configure-n8n/basic-configuration/use-environment-variables/database)
- [Variáveis de ambiente — Deployment](https://docs.n8n.io/deploy/host-n8n/configure-n8n/basic-configuration/use-environment-variables/deployment)
- [Imagem Docker Hub — n8nio/n8n](https://hub.docker.com/r/n8nio/n8n/tags)
- [Regras de infraestrutura do projeto BIA](.kiro/rules/infraestrutura.md)

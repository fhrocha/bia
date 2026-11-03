# Diagrama de Arquitetura — n8n na AWS

**Região:** us-east-2 (Ohio)  
**Conta:** 600579993826  
**Data:** 2026-11-03  

---

## Diagrama

```mermaid
graph TD
    User(["👤 Usuário\nn8n-bia.acme.app.br"])

    subgraph DNS ["DNS"]
        R53["🌐 Route 53\nn8n-bia.acme.app.br\nA Alias"]
        ACM["🔒 ACM\n*.acme.app.br\nISSUED"]
    end

    subgraph AWS ["AWS — us-east-2"]

        subgraph VPC ["VPC Default (vpc-0c8a1ecba7f28b60d)"]

            subgraph AZA ["us-east-2a (subnet-0c2bbc5f46eeb2eb6)"]

                subgraph SGALB ["sg: n8n-alb\nInbound: 80, 443 — 0.0.0.0/0"]
                    ALB["⚖️ ALB\nn8n-alb\nListener: HTTPS 443"]
                end

                subgraph SGEC2 ["sg: n8n-ec2\nInbound: All TCP — n8n-alb"]
                    EC2["🖥️ EC2 t3.micro\ni-0f7efccfb63211257\nASG: asg-cluster-n8n"]
                    ECS["📦 ECS cluster-n8n\nservice-bia-n8n\ntask-bia-n8n:1\nn8nio/n8n:stable"]
                end

                subgraph SGDB ["sg: n8n-db\nInbound: 5432 — n8n-ec2"]
                    RDS["🗄️ RDS PostgreSQL 17.11\nn8n-db (db.t4g.micro)\nn8n-db.cviswcg8idvc\n.us-east-2.rds.amazonaws.com"]
                end

            end

            subgraph AZB ["us-east-2b (subnet-0b8ac41495b453459)"]
                ALBAZB["⚖️ ALB\n(nó us-east-2b)"]
            end

            TG["🎯 Target Group\ntg-n8n\nHTTP:5678\nderegistration: 30s"]

        end

    end

    User -->|"HTTPS"| R53
    R53 -->|"Alias"| ALB
    ACM -.->|"certificado"| ALB
    ALB --> TG
    ALB <-.-> ALBAZB
    TG -->|"porta dinâmica"| EC2
    EC2 --> ECS
    ECS -->|"PostgreSQL TLS\n5432"| RDS
```

---

## Legenda dos Recursos

| Ícone | Recurso | ID / ARN |
|---|---|---|
| 🌐 | Route 53 `n8n-bia.acme.app.br` | Hosted Zone `Z03773583SL3DJ9VMWZ2H` |
| 🔒 | ACM `*.acme.app.br` | `arn:aws:acm:us-east-2:600579993826:certificate/7a78ed7e-a696-4b03-9820-7c5c22066728` |
| ⚖️ | ALB `n8n-alb` | `arn:...:loadbalancer/app/n8n-alb/13172bdeb496c4b1` |
| 🎯 | Target Group `tg-n8n` | `arn:...:targetgroup/tg-n8n/b946b2dc64bdf4a1` |
| 🖥️ | EC2 `i-0f7efccfb63211257` | `t3.micro` — ASG `asg-cluster-n8n` |
| 📦 | ECS `service-bia-n8n` | `arn:aws:ecs:us-east-2:600579993826:service/cluster-n8n/service-bia-n8n` |
| 🗄️ | RDS `n8n-db` | `arn:aws:rds:us-east-2:600579993826:db:n8n-db` |

---

## Security Groups — Fluxo de Acesso

```mermaid
graph LR
    Internet(["🌍 Internet\n0.0.0.0/0"])
    SGALB["n8n-alb\nsg-0cbf8ff2876de50ea"]
    SGEC2["n8n-ec2\nsg-0602e05ef5b9cb34e"]
    SGDB["n8n-db\nsg-0cdaa426c986859ca"]

    Internet -->|"TCP 80, 443"| SGALB
    SGALB -->|"All TCP\n(portas dinâmicas ECS)"| SGEC2
    SGEC2 -->|"TCP 5432\nPostgreSQL"| SGDB
```

---

## Fluxo de Requisição

```mermaid
sequenceDiagram
    actor User as 👤 Usuário
    participant R53 as Route 53
    participant ALB as ALB (HTTPS 443)
    participant TG as Target Group
    participant ECS as ECS Task (n8n)
    participant RDS as RDS PostgreSQL

    User->>R53: https://n8n-bia.acme.app.br
    R53->>ALB: Alias → n8n-alb DNS
    ALB->>ALB: Termina TLS (cert *.acme.app.br)
    ALB->>TG: HTTP forward
    TG->>ECS: porta dinâmica → container :5678
    ECS->>RDS: PostgreSQL TLS :5432
    RDS-->>ECS: dados
    ECS-->>User: resposta HTTP
```

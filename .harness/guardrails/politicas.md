# Políticas de guardrail 

## A IA nunca toca 
- os diretórios: context, evals, guardrails — só humano. 
- Nada de segredo no contexto. Nunca.
- Nada de informações pessoais sensíveis no contexto. Nunca.

## Sempre exige revisão humana 
- Registro de nova análise de ativo.
- Registro de atualização de carteira. 
- Qualquer PR gerado majoritariamente por agente.

## Regras OBRIGATÓORIAS do projeto
- Sempre considerar essas regras como OBRIGATÓORIAS e inegociáveis para esse projeto (ver `.kiro/rules/`)
- Dockerfile: SEMPRE single-stage, base `public.ecr.aws/docker/library/node:*-slim`,
  WORKDIR `/usr/src/app`, sem multi-stage/chmod/usuários não-root; nunca sobrescrever
  Dockerfile existente sem avisar. Detalhes em `.kiro/rules/dockerfile.md`.
- Infra: simplicidade acima de complexidade (público aluno); seguir nomes de SG/cluster/
  task-def de `.kiro/rules/infraestrutura.md`; não incluir Secrets Manager/multi-AZ novos.
- `CLAUDE.md` define persona DevOps do projeto e importa essas rules + `AmazonQ.md`.

# AGENTS.md — Projeto BIA

App educacional (Formação AWS): backend Node/Express na raiz, frontend React+Vite em `client/`, PostgreSQL via Sequelize, cache Redis/Valkey. Documentação e regras em português.

## Entrypoints (não óbvio)
- Backend real: `server.js` → `config/express.js` (porta 8080 via `config/default.json`).
- `index.js` na raiz é LEGADO/não usado — não tomar como entrypoint.
- Frontend: `client/` (Vite); build vai para `client/build`, servido estático pelo Express.
- Rotas da API registradas em `config/express.js` (`api/routes/*`).
- Health check canônico: `GET /api/versao` (não usa banco). `GET /api/tarefas` usa o banco.

## Comandos
- Testes (unitários, Jest): `npm test` (= `jest tests/unit`).
  Teste único: `npx jest tests/unit/controllers/versao.test.js`
- Subir banco local: `docker compose up -d database` (Postgres exposto em localhost:5433).
- Migrations: `npx sequelize db:migrate` (paths em `.sequelizerc`; dir `database/migrations`).
- Rodar app: `npm install && npm run build --prefix client && npm start`
  (ou `scripts/ligar_bia_local.sh`, que faz tudo + migrate).
- Stack completa Docker: `docker compose up` — app em http://localhost:3001.
  Migration no container: `docker compose exec server bash -c 'npx sequelize db:migrate'`
- Build do client exige `VITE_API_URL` em tempo de build (ex.: `http://localhost:3001`).

## Banco / env
- `config/database.js` lê `DB_USER`, `DB_PWD`, `DB_HOST`, `DB_PORT`
  (defaults: postgres/postgres @ 127.0.0.1:5433, database `bia`).
- `DB_SECRET_NAME` + `DB_REGION` ativam Secrets Manager; `IS_LOCAL=true` usa credenciais
  de env. Não usar credenciais estáticas em infra AWS — usar role da instância.
- Cache: `CACHE_ENDPOINT`, `CACHE_PORT`, `CACHE_TTL`, `CACHE_TLS` (ver compose.yml).

## CI/CD e infra
- Pipeline = CodePipeline + CodeBuild: `buildspec.yml` faz build da imagem, push no ECR
  (env `ECR_REGISTRY`/`ECR_REPO` lá) e gera `imagedefinitions.json` para deploy no ECS.
- Deploy alvo: ECS em cluster EC2 (não Fargate). Nomenclatura e cenários obrigatórios
  em `.kiro/rules/infraestrutura.md`.
- Scripts locais de AWS (`build.sh`, `deploy.sh`) usam profile `formacaoaws`.

## Harness de IA (.harness/)
- Estrutura de uso de IA do projeto: `context/`, `prompts/`, `tools/`,
  `guardrails/`, `evals/`. Dono: Fábio — mudanças só via PR revisado por ele.
- GUARDRAIL: a IA NUNCA edita `.harness/context/`, `.harness/evals/`,
  `.harness/guardrails/` (somente humanos); nunca incluir segredos ou dados
  pessoais sensíveis no contexto.
- PRs gerados majoritariamente por agente exigem revisão humana (ver
  `.harness/guardrails/politicas.md`).
- Prompts reutilizáveis em `.harness/prompts/` (ex.: `executar-projeto.md`,
  que referencia `CLAUDE.md` e `AmazonQ.md`).
- Regras a serem utilizadas (ver `.harness/guardrails/politicas.md`)
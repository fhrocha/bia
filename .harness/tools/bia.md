# Agente BIA (opencode)

Agente com escopo **apenas neste projeto** que espelha o agente BIA configurado para o Kiro.

## Origem

- Definição original: `.kiro/agents/bia.json`
- Prompt canônico: `.harness/prompts/bia.md`
- Agente opencode: `.opencode/agent/bia.md`
- MCP do projeto: `opencode.json`

## Configuração

- **Modo:** `all` (primário e subagente).
- **Modelo:** herda o modelo padrão do opencode.
- **MCP servers:**
  - `postgres` — `uvx --with "mcp<2" postgres-mcp postgresql://postgres:postgres@localhost:5433/bia`
  - `aws-mcp` — `uvx mcp-proxy-for-aws@latest https://aws-mcp.us-east-1.api.aws/mcp --metadata AWS_REGION=us-east-1`
- **Resources carregados pelo prompt:** `README.md`, `AmazonQ.md`, `AGENTS.md`, `CLAUDE.md` e `.kiro/rules/*.md`.
- **Permissões:** edição liberada, exceto `.harness/context/**`, `.harness/evals/**` e `.harness/guardrails/**`.

## Como usar

- Na TUI do opencode, selecione o agente `bia`.
- Ou invoque como subagente pelo tool `task`, informando `subagent_type: bia`.

> A configuração MCP do opencode é global por projeto. Por isso os servidores ficam em `opencode.json`, que só é carregado dentro deste repositório.

## Observações

- `postgres` usa as credenciais locais de desenvolvimento já presentes em `compose.yml` e `.kiro/` (não é um segredo novo).
- O `.kiro/settings/aws-mcp.json` aponta para `us-east-2`; este espelho usa `us-east-1`, conforme `.kiro/rules/infraestrutura.md`.
- A configuração do Kiro não foi alterada.

# [005] GitHub Actions - Executar testes automaticamente em Pull Requests

## Tipo
`feat`

## Agente Responsável
`devops` (.kiro/agents/devops.json)

## Branch
- **Base:** `bia-desafio-agosto`
- **Branch da task:** `feature/005-feat-github-actions-testes-pr`

---

## Modelo de Trabalho

- Cada task possui seu próprio branch, derivado de `bia-desafio-agosto`
- O agente responsável deve seguir os passos abaixo antes de iniciar a implementação

---

## Instruções de Início

Ao iniciar esta task, o agente deve:

1. Verificar se está no branch `bia-desafio-agosto`. Caso não esteja, informar e perguntar se pode retornar a ele antes de prosseguir.
2. Após autorizado: mover este arquivo para `.kiro/tasks/doing/`, fazer commit e push no branch `bia-desafio-agosto`.
3. Criar o branch `feature/005-feat-github-actions-testes-pr` a partir de `bia-desafio-agosto` e iniciar a implementação.

---

## Descrição

Implementar um workflow do GitHub Actions que execute automaticamente os testes unitários do projeto sempre que um Pull Request for aberto ou atualizado contra a branch `bia-desafio-agosto`. Isso garantirá que todas as mudanças sejam validadas antes do merge, prevenindo a introdução de bugs.

## Contexto

Atualmente, o projeto possui 16 testes unitários (Jest) que validam os controllers de `tarefas` e `versao`. Esses testes são executados manualmente com `npm test`. Com o crescimento do projeto e o fluxo de trabalho baseado em feature branches e Pull Requests, é essencial automatizar a execução dos testes para garantir qualidade contínua.

**Testes existentes:**
- `tests/unit/controllers/tarefas.test.js` - 12 testes (CRUD)
- `tests/unit/controllers/versao.test.js` - 3 testes

**Framework:** Jest 27.5.1

## Critérios de Aceite

- [x] Workflow do GitHub Actions criado em `.github/workflows/`
- [x] Workflow deve ser acionado nos eventos:
  - `pull_request` (opened, synchronize, reopened) contra `bia-desafio-agosto`
  - Opcionalmente: `push` para branches `feature/*` (para feedback mais rápido)
- [x] Workflow deve instalar dependências do Node.js
- [x] Workflow deve executar `npm test`
- [x] Workflow deve falhar se algum teste falhar
- [x] Status do workflow deve aparecer no Pull Request
- [x] Workflow deve usar Node.js versão 18.x ou superior
- [x] Logs dos testes devem estar visíveis no GitHub Actions

## Arquivos a Criar

| Ação | Arquivo |
|------|---------|
| Criar | `.github/workflows/test-pr.yml` |

## Estrutura do Workflow

O workflow deve conter no mínimo:

```yaml
name: Testes Automatizados em PR

on:
  pull_request:
    branches:
      - bia-desafio-agosto
    types: [opened, synchronize, reopened]

jobs:
  test:
    name: Executar Testes Unitários
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        node-version: [18.x]
    
    steps:
      - name: Checkout do código
        uses: actions/checkout@v4
      
      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'
      
      - name: Instalar dependências
        run: npm ci
      
      - name: Executar testes
        run: npm test
```

## Melhorias Opcionais (Não Obrigatórias)

- Adicionar cache para `node_modules` para acelerar builds
- Adicionar badge de status no README.md
- Adicionar step para gerar relatório de cobertura de testes
- Testar em múltiplas versões do Node.js (18.x, 20.x)
- Adicionar timeout para os jobs

## Validação

Após implementação, validar que:

1. O workflow aparece na aba "Actions" do repositório
2. Ao abrir um PR de teste, o workflow é acionado automaticamente
3. Os logs mostram a execução de 16 testes
4. O status (✓ ou ✗) aparece no PR
5. PRs com testes falhando não podem ser mergeados (se configurado branch protection)

## Notas Técnicas

- Usar `npm ci` ao invés de `npm install` para instalação determinística
- O workflow será executado em runners do GitHub (sem custos para repos públicos)
- Não há necessidade de configurar banco de dados, pois os testes usam mocks
- O diretório `.github/` deve ser criado na raiz do projeto

---

## Checklist do Agente `devops`

> Marque cada item à medida que for concluído durante a implementação.

- [x] Verificar branch atual — confirmar que está em `bia-desafio-agosto`
- [x] Mover este arquivo para `.kiro/tasks/doing/`
- [x] Fazer commit e push no branch `bia-desafio-agosto`
- [x] Criar o branch `feature/005-feat-github-actions-testes-pr` a partir de `bia-desafio-agosto`
- [x] Criar diretório `.github/workflows/` na raiz do projeto
- [x] Criar arquivo `test-pr.yml` com configuração do workflow
- [x] Configurar triggers: `pull_request` para branch `bia-desafio-agosto`
- [x] Configurar job com Node.js 18.x
- [x] Adicionar step de checkout do código
- [x] Adicionar step de setup do Node.js
- [x] Adicionar step para instalar dependências (`npm ci`)
- [x] Adicionar step para executar testes (`npm test`)
- [ ] Testar o workflow localmente se possível (com `act` ou similar)
- [x] Fazer commit das alterações
- [x] Push do branch `feature/005-feat-github-actions-testes-pr`
- [ ] Criar um PR de teste para validar o workflow
- [ ] Verificar que o workflow foi executado e passou
- [ ] Capturar evidências (screenshots ou logs)
- [ ] Informar ao `po` que a task está pronta para encerramento

---

## Encerramento — Responsabilidade do `po`

Quando o agente `devops` concluir e sinalizar a finalização, o `po` deve:

- [ ] Verificar se todos os critérios de aceite foram atendidos
- [ ] Confirmar que todos os itens do checklist do agente estão marcados
- [ ] Validar que o workflow está funcionando (acessar aba Actions no GitHub)
- [ ] Validar que o workflow é executado em novos PRs
- [ ] Informar ao usuário que a task está finalizada
- [ ] Mover este arquivo para `.kiro/tasks/done/`
- [ ] Fazer commit e push final (branch `feature/005-feat-github-actions-testes-pr`)
- [ ] Seguir o fluxo de Pull Request conforme especificado em `.kiro/po/especificacao.md`
  - [ ] Validação Pré-PR
  - [ ] Criação do Pull Request
  - [ ] Aprovação e Merge
  - [ ] Registro Final

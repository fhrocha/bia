# [001] Tela de Versão da API

## Tipo
`feat`

## Descrição
Implementar uma tela dedicada para exibição das informações retornadas pela rota `/api/versao`, seguindo o mesmo padrão visual da tela de tarefas (`Tasks.jsx`).

## Contexto
A rota `/api/versao` já existe no backend e retorna uma string com a versão da aplicação (ex: `Bia 4.3.0`). Atualmente, essa informação é exibida apenas como um pequeno tooltip no `VersionInfo.jsx`. O objetivo é criar uma **página completa** acessível via rota do React Router, com o mesmo visual da tela de tarefas.

## Critérios de Aceite

- [ ] Criar o componente `Versao.jsx` em `client/src/components/`
- [ ] O componente deve chamar a rota `/api/versao` e exibir a resposta
- [ ] O layout deve seguir o padrão visual do componente `Tasks.jsx`:
  - Mesma estrutura de container (`.tasks-container`)
  - Mesmo estilo de card/item que o componente `Task.jsx`
  - Utilizar classes CSS já existentes no projeto (`index.css`)
- [ ] Registrar a rota `/versao` no `App.jsx` (React Router)
- [ ] Adicionar link para a nova rota no `Header.jsx`
- [ ] Exibir as seguintes informações na tela:
  - Nome da aplicação (ex: `Bia`)
  - Número da versão (ex: `4.3.0`)
  - Status da API (online/offline/verificando), com ícone visual
  - URL da API sendo utilizada
- [ ] Estado de loading enquanto a requisição está em andamento
- [ ] Estado de erro caso a API esteja indisponível

## Arquivos a Criar/Modificar

| Ação | Arquivo |
|------|---------|
| Criar | `client/src/components/Versao.jsx` |
| Modificar | `client/src/App.jsx` (adicionar rota `/versao`) |
| Modificar | `client/src/components/Header.jsx` (adicionar link) |

## Referências Visuais
- Padrão de container: `Tasks.jsx` → classe `.tasks-container`
- Padrão de item: `Task.jsx` → classe `.task`
- Dados do endpoint: `api/controllers/versao.js` → retorna `Bia {VERSAO_API}`
- Lógica de chamada existente: `VersionInfo.jsx` → método `checkApiHealth()`

## Notas Técnicas
- A variável de ambiente `VITE_API_URL` deve ser usada para montar a URL da API (conforme padrão já adotado no `App.jsx`)
- Não criar CSS novo desnecessariamente — reaproveitar as classes existentes do `index.css`
- Não utilizar multi-stage builds ou lógica complexa — manter simplicidade

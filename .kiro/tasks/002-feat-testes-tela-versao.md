# [002] Testes da Tela de Versão

## Tipo
`feat`

## Descrição
Implementar testes automatizados para o componente `Versao.jsx`, cobrindo os principais cenários de uso: carregamento, exibição dos dados retornados pela API, estado de erro e estado de loading.

## Contexto
A tarefa [001] criou o componente `Versao.jsx`, responsável por consumir a rota `/api/versao` e exibir as informações de versão da aplicação. Agora é necessário garantir o funcionamento correto desse componente por meio de testes unitários, utilizando o framework de testes já presente no projeto (Jest).

## Critérios de Aceite

- [ ] Criar o arquivo de testes `client/src/components/Versao.test.jsx` (ou equivalente conforme padrão do projeto)
- [ ] Testar o estado de **loading**: verificar que a mensagem/indicador de carregamento é exibido enquanto a requisição está em andamento
- [ ] Testar o **sucesso**: mockar a rota `/api/versao` retornando `"Bia 4.3.0"` e verificar que:
  - O nome da aplicação é exibido (`Bia`)
  - O número da versão é exibido (`4.3.0`)
  - O status exibe "online"
- [ ] Testar o **erro**: mockar a rota `/api/versao` falhando e verificar que o estado de erro é exibido corretamente
- [ ] Todos os testes devem passar ao executar `npm test` na raiz do projeto

## Arquivos a Criar/Modificar

| Ação | Arquivo |
|------|---------|
| Criar | `client/src/components/Versao.test.jsx` |

## Referências
- Componente a ser testado: `client/src/components/Versao.jsx`
- Endpoint mockado: `/api/versao` → retorna `"Bia 4.3.0"`
- Padrão de testes existente: pasta `tests/` na raiz do projeto
- Framework: Jest (já configurado no `package.json`)

## Notas Técnicas
- Usar `jest.mock` ou `fetch mock` para interceptar chamadas à API — não fazer chamadas reais ao backend
- Manter os testes simples e diretos, sem abstrações desnecessárias
- Seguir o padrão de testes já adotado no projeto
- Não testar implementações internas do componente — focar no comportamento visível ao usuário

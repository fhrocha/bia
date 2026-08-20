# [004] feat - Simplificar tela de versão

## Modelo de Trabalho
- **Branch model:** feature/branch — cada task possui seu próprio branch
- **Branch base:** `bia-desafio-agosto` (o branch desta task DEVE derivar dele)
- **Branch da task:** `004-feat-simplificar-tela-versao`
- **Agent responsável:** dev

## Instruções de Início (obrigatório antes de implementar)

1. Verificar se o branch atual é `bia-desafio-agosto`.
   - Caso não esteja, informar e perguntar se pode retornar antes de prosseguir.
2. Após autorizado:
   - Mover este arquivo para `.kiro/tasks/doing/`
   - Fazer commit e push no branch `bia-desafio-agosto`
   - Criar e fazer checkout do branch `004-feat-simplificar-tela-versao`

---

## Descrição

A tela de versão (`/versao`) exibe atualmente quatro informações:

| Campo | Valor de exemplo |
|---|---|
| Nome da aplicação | Bia |
| Versão | 4.3.0 |
| Status da API | 🟢 Online |
| URL da API | http://localhost:3001 |

A exibição de **Status da API** e **URL da API** não é necessária para os usuários finais. Essas informações devem ser removidas, deixando a tela mais simples e focada.

---

## Objetivo

Simplificar a tela de versão exibindo **apenas**:
1. Nome da aplicação
2. Versão

---

## Arquivo a modificar

`client/src/components/Versao.jsx`

---

## Critérios de Aceite

- [ ] A tela de versão exibe somente **Nome da aplicação** e **Versão**
- [ ] Os blocos de **Status da API** e **URL da API** foram removidos do JSX
- [ ] O estado `status` e a lógica de fetch à API podem ser mantidos internamente (para buscar a versão), mas **não devem ser exibidos** na interface
- [ ] Os estados e variáveis relacionados exclusivamente à exibição do status (`statusIcone`, `statusLabel`, `erro`) podem ser removidos se não forem mais utilizados
- [ ] A tela de loading (`🟡 Verificando API...`) e o bloco de erro (`🔴 API indisponível`) devem ser avaliados — se mantidos, devem ser simples e não expor a URL da API
- [ ] O botão "← Voltar" permanece visível
- [ ] A aplicação compila e funciona sem erros no ambiente local

---

## Contexto Técnico

- **Componente:** `client/src/components/Versao.jsx`
- **Fonte dos dados:** `GET /api/versao` — retorna texto no formato `"Bia 4.3.0"`
- **Parse atual:** `versaoTexto.split(" ")` → `[nomeApp, numeroVersao]`
- **A lógica de fetch pode ser simplificada** junto com a remoção dos blocos de UI desnecessários

---

## Finalização

Após implementar e testar localmente:
- Fazer commit e push no branch `004-feat-simplificar-tela-versao`

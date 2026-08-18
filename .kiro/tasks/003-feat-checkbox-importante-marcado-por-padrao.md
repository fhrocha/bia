# [003] Checkbox "Importante" marcado por padrão no cadastro de tarefa

## Tipo
`feat`

## Descrição
Na tela de cadastro de tarefa, o checkbox **Importante** deve vir marcado por padrão ao abrir o formulário. O usuário poderá desmarcá-lo caso a tarefa não seja importante.

## Contexto Técnico
- **Arquivo:** `client/src/components/AddTask.jsx`
- **Estado atual:** `const [importante, setImportante] = useState(false);`
- **Comportamento atual:** O checkbox começa desmarcado.
- **Comportamento esperado:** O checkbox começa marcado.

## Critérios de Aceite
- [ ] Ao abrir a tela de cadastro, o checkbox "Importante" deve estar marcado (`checked`) por padrão.
- [ ] Após salvar uma tarefa, o checkbox deve voltar a ser marcado (comportamento do reset após submit).
- [ ] O usuário ainda deve conseguir desmarcar o checkbox antes de salvar.
- [ ] Nenhum outro comportamento do formulário deve ser alterado.

## O que NÃO deve ser alterado
- Layout e estilo do formulário
- Lógica de validação do campo título
- Comportamento dos demais campos (título, data/prazo)

## Implementação Sugerida
Alterar apenas o valor inicial do estado `importante` no componente `AddTask.jsx`:

```js
// De:
const [importante, setImportante] = useState(false);

// Para:
const [importante, setImportante] = useState(true);
```

E também ajustar o reset após o submit:

```js
// De:
setImportante(false);

// Para:
setImportante(true);
```

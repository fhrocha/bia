# [003] Checkbox "Importante" marcado por padrão no cadastro de tarefas

## Tipo
`feat`

## Agente Responsável
`dev` (.kiro/agents/dev.json)

## Branch
- **Base:** `bia-desafio-agosto`
- **Branch da task:** `feature/003-feat-checkbox-importante-padrao`

## Instruções de Início

Ao iniciar esta task, o agente deve:

1. Verificar se está no branch `bia-desafio-agosto`. Caso contrário, informar e perguntar se pode retornar a ele antes de prosseguir.
2. Após autorizado: mover este arquivo para a pasta `doing/`, fazer commit e push no branch `bia-desafio-agosto`.
3. Criar o branch `feature/003-feat-checkbox-importante-padrao` a partir de `bia-desafio-agosto` e iniciar a implementação.

---

## Descrição
No formulário de cadastro de tarefas (`AddTask.jsx`), o checkbox **"Importante"** deve vir **marcado por padrão** ao abrir a tela. O usuário ainda poderá desmarcá-lo manualmente antes de salvar.

## Contexto
Atualmente o estado inicial do checkbox `importante` no componente `AddTask.jsx` é `false`, deixando-o desmarcado ao abrir o formulário. Como a maioria das tarefas cadastradas pelos usuários são consideradas importantes, faz sentido que o padrão seja marcado, reduzindo o esforço necessário no cadastro.

## Critérios de Aceite

- [ ] Ao abrir o formulário de cadastro de tarefas, o checkbox "Importante" deve estar **marcado por padrão**
- [ ] O usuário deve conseguir **desmarcar** o checkbox normalmente
- [ ] Após salvar uma tarefa e o formulário ser resetado, o checkbox deve voltar a ficar **marcado** (padrão)
- [ ] Nenhum outro comportamento do formulário deve ser alterado

## Arquivos a Modificar

| Ação | Arquivo |
|------|---------|
| Modificar | `client/src/components/AddTask.jsx` |

## Implementação
A única alteração necessária é no estado inicial do hook `useState` para o campo `importante`:

```jsx
// Antes
const [importante, setImportante] = useState(false);

// Depois
const [importante, setImportante] = useState(true);
```

O reset após o envio do formulário (`setImportante(true)`) já deve estar alinhado com o novo padrão.

## Notas Técnicas
- Mudança simples e cirúrgica — apenas o valor inicial do `useState`
- Não alterar nenhuma outra lógica do componente
- Verificar que o reset do formulário (após `onSubmit`) também usa `true` para manter a consistência

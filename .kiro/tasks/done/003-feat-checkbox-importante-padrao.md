# [003] Checkbox "Importante" marcado por padrão no cadastro de tarefas

## Tipo
`feat`

## Agente Responsável
`dev` (.kiro/agents/dev.json)

## Branch
- **Base:** `bia-desafio-agosto`
- **Branch da task:** `feature/003-feat-checkbox-importante-padrao`

---

## Modelo de Trabalho

- Cada task possui seu próprio branch, derivado de `bia-desafio-agosto`
- O agente responsável deve seguir os passos abaixo antes de iniciar a implementação

---

## Instruções de Início

Ao iniciar esta task, o agente deve:

1. Verificar se está no branch `bia-desafio-agosto`. Caso não esteja, informar e perguntar se pode retornar a ele antes de prosseguir.
2. Após autorizado: mover este arquivo para `.kiro/tasks/doing/`, fazer commit e push no branch `bia-desafio-agosto`.
3. Criar o branch `feature/003-feat-checkbox-importante-padrao` a partir de `bia-desafio-agosto` e iniciar a implementação.

---

## Descrição
No formulário de cadastro de tarefas (`AddTask.jsx`), o checkbox **"Importante"** deve vir **marcado por padrão** ao abrir a tela. O usuário ainda poderá desmarcá-lo manualmente antes de salvar.

## Contexto
Atualmente o estado inicial do checkbox `importante` no componente `AddTask.jsx` é `false`, deixando-o desmarcado ao abrir o formulário. Como a maioria das tarefas cadastradas pelos usuários são consideradas importantes, faz sentido que o padrão seja marcado, reduzindo o esforço necessário no cadastro.

## Critérios de Aceite

- [x] Ao abrir o formulário de cadastro de tarefas, o checkbox "Importante" deve estar **marcado por padrão**
- [x] O usuário deve conseguir **desmarcar** o checkbox normalmente
- [x] Após salvar uma tarefa e o formulário ser resetado, o checkbox deve voltar a ficar **marcado** (padrão)
- [x] Nenhum outro comportamento do formulário deve ser alterado

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

---

## Checklist do Agente `dev`

> Marque cada item à medida que for concluído durante a implementação.

- [x] Verificar branch atual — confirmar que está em `bia-desafio-agosto`
- [x] Mover este arquivo para `.kiro/tasks/doing/`
- [x] Fazer commit e push no branch `bia-desafio-agosto`
- [x] Criar o branch `feature/003-feat-checkbox-importante-padrao` a partir de `bia-desafio-agosto`
- [x] Localizar o estado `importante` em `client/src/components/AddTask.jsx`
- [x] Alterar `useState(false)` para `useState(true)` no campo `importante`
- [x] Verificar que o reset do formulário também usa `true` (após `onSubmit`)
- [x] Testar manualmente: abrir formulário e confirmar checkbox marcado por padrão
- [x] Testar que é possível desmarcar o checkbox normalmente
- [x] Testar que após salvar, o checkbox volta a ficar marcado
- [x] Confirmar que nenhum outro comportamento do formulário foi alterado
- [x] Fazer commit e push no branch `feature/003-feat-checkbox-importante-padrao`
- [x] Informar ao `po` que a task está pronta para encerramento

---

## Encerramento — Responsabilidade do `po`

Quando o agente `dev` concluir e sinalizar a finalização, o `po` deve:

- [x] Verificar se todos os critérios de aceite foram atendidos
- [x] Confirmar que todos os itens do checklist do agente estão marcados
- [x] Validar que o comportamento descrito está implementado corretamente
- [x] Informar ao usuário que a task está finalizada
- [x] Mover este arquivo para `.kiro/tasks/done/`
- [x] Fazer commit e push final (branch `feature/003-feat-checkbox-importante-padrao`)

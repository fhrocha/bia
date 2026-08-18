# 003 - feat - Checkbox "Importante" marcado por padrão no cadastro de tarefa

## Modelo de Trabalho
- **Branch base:** `bia-desafio-agosto`
- **Branch da task:** `003-feat-checkbox-importante-marcado-por-padrao`
- **Agent responsável:** dev

## Instruções de Início para o Agent

1. Verificar se estamos no branch `bia-desafio-agosto`.
   - Caso não esteja, informar ao usuário e aguardar autorização para retornar antes de prosseguir.
2. Após autorização:
   - Mover este arquivo de `.kiro/tasks/` para `.kiro/tasks/doing/`
   - Fazer commit e push no branch `bia-desafio-agosto`
   - Criar e fazer checkout do branch `003-feat-checkbox-importante-marcado-por-padrao`
3. Iniciar a implementação conforme especificado abaixo.

---

## Descrição
Na tela de cadastro de tarefa, o checkbox "Importante" deve vir marcado por padrão ao abrir o formulário. Após o envio do formulário, o campo deve retornar ao estado padrão (marcado).

## Arquivo Alvo
`client/src/components/AddTask.jsx`

## Mudança Esperada

### Estado inicial do checkbox
**Antes:**
```js
const [importante, setImportante] = useState(false);
```
**Depois:**
```js
const [importante, setImportante] = useState(true);
```

### Reset após submit
**Antes:**
```js
setImportante(false);
```
**Depois:**
```js
setImportante(true);
```

## Critérios de Aceite
- [ ] Ao abrir o formulário de cadastro de tarefa, o checkbox "Importante" deve estar marcado por padrão.
- [ ] O comportamento do checkbox continua funcionando normalmente (o usuário pode desmarcar).
- [ ] Após salvar uma tarefa, o formulário é resetado com o checkbox "Importante" marcado novamente.
- [ ] Nenhuma outra funcionalidade do formulário foi alterada.

## Observações
- A alteração é exclusivamente no estado inicial (`useState`) e no reset pós-submit.
- Não há alteração visual no componente, apenas no valor padrão do estado.

# Task 007 - Adicionar Componente de Calendário no Campo Data/Prazo

## 📋 Informações da Task

**Tipo:** feat  
**Agente Responsável:** dev  
**Branch:** feature/007-feat-adicionar-componente-calendario-data  
**Branch Base:** bia-desafio-agosto

---

## 🎯 Objetivo

Implementar um componente de calendário (date picker) no campo "Data/Prazo" da tela home da BIA, substituindo o input de texto atual por um seletor de data visual. O valor deve continuar sendo persistido no banco como string, mantendo compatibilidade com a estrutura atual.

---

## 📝 Descrição Detalhada

Atualmente o campo "Data/Prazo" no componente `AddTask.jsx` é um input de texto livre. O objetivo é transformá-lo em um componente de calendário interativo que permita ao usuário selecionar uma data de forma visual.

### Requisitos Funcionais:
- Substituir o input de texto por um date picker (componente de calendário)
- Manter a persistência como string no banco de dados
- Formato da data: dd/mm/yyyy (padrão brasileiro)
- O calendário deve ter boa usabilidade mobile e desktop
- Manter a validação existente (se não preenchido, usar data atual)

### Requisitos Técnicos:
- Utilizar biblioteca de date picker compatível com React 18.3.1
- Sugestão: `react-datepicker` (leve, amplamente usado, bem documentado)
- Manter a arquitetura de estado local do componente
- Não quebrar funcionalidades existentes
- Seguir o padrão visual da aplicação

---

## 🔧 Implementação Técnica

### 1. Instalação de Dependência
```bash
npm install react-datepicker --save
npm install --save-dev @types/react-datepicker  # se usar TypeScript
```

### 2. Modificações Necessárias

**Arquivo:** `client/src/components/AddTask.jsx`

**Mudanças:**
- Importar `DatePicker` do `react-datepicker`
- Importar CSS do `react-datepicker`
- Alterar o state `dia` para trabalhar com objeto Date
- Converter Date para string no formato dd/mm/yyyy antes de enviar ao backend
- Substituir o input de texto pelo componente `<DatePicker />`

**Exemplo de conversão:**
```javascript
// Estado interno: Date object
const [dia, setDia] = useState(new Date());

// Ao enviar: converter para string
const dataFormatada = dia.toLocaleDateString('pt-BR');
```

### 3. Configurações do DatePicker
- `dateFormat="dd/MM/yyyy"`: Formato brasileiro
- `locale="pt-BR"`: Idioma português (importar locale se necessário)
- `placeholderText="Selecione uma data"`: Placeholder amigável
- `className`: Manter consistência visual com outros inputs

---

## 🎨 Estilo e UX

- O DatePicker deve ter a mesma aparência dos outros campos do formulário
- Adicionar CSS customizado se necessário para manter consistência visual
- O calendário deve ser responsivo (funcionar bem em mobile)
- Testar navegação por teclado (acessibilidade)

---

## ✅ Checklist de Implementação

### Pré-requisitos
- [ ] Verificar se está no branch `bia-desafio-agosto`
- [ ] Se não estiver, perguntar autorização para retornar ao branch base
- [ ] Após autorizado, mover esta task para `.kiro/tasks/doing/`
- [ ] Fazer commit e push da movimentação no branch `bia-desafio-agosto`
- [ ] Criar worktree: `git worktree add -b feature/007-feat-adicionar-componente-calendario-data .worktrees/007-feat-calendario bia-desafio-agosto`
- [ ] Entrar no worktree: `cd .worktrees/007-feat-calendario`
- [ ] Confirmar que está na branch correta: `git branch --show-current`

### Desenvolvimento
- [ ] Instalar dependência `react-datepicker` no diretório `client/`
- [ ] Modificar `client/src/components/AddTask.jsx`
- [ ] Importar `DatePicker` e seus estilos
- [ ] Alterar o state `dia` para trabalhar com Date
- [ ] Implementar conversão de Date para string no formato brasileiro
- [ ] Substituir input de texto pelo componente DatePicker
- [ ] Testar localmente a seleção de data
- [ ] Verificar se a data está sendo persistida corretamente no formato string
- [ ] Garantir que a validação (data padrão se vazio) continua funcionando
- [ ] Verificar responsividade do calendário

### Testes Locais
- [ ] Rodar o frontend: `npm run dev` (dentro de `client/`)
- [ ] Testar criação de tarefa com data selecionada pelo calendário
- [ ] Verificar formato da data salva no banco (deve ser string dd/mm/yyyy)
- [ ] Testar em diferentes resoluções (desktop e mobile)
- [ ] Testar navegação por teclado (Tab, Enter, Esc)
- [ ] Verificar se não há erros no console

### Qualidade de Código
- [ ] Código está seguindo padrões do projeto
- [ ] Sem warnings ou erros no console
- [ ] Imports organizados
- [ ] Nomes de variáveis claros e em português (padrão do projeto)

### Finalização
- [ ] Fazer commit das mudanças: `git add . && git commit -m "feat: adicionar date picker no campo data/prazo"`
- [ ] Push do branch: `git push origin feature/007-feat-adicionar-componente-calendario-data`
- [ ] Criar Pull Request: `gh pr create --base bia-desafio-agosto --head feature/007-feat-adicionar-componente-calendario-data --title "[007] feat: Adicionar calendário no campo Data/Prazo" --body "Implementa date picker para seleção visual de data"`
- [ ] Informar ao PO que a task está pronta para validação

---

## 🧪 Critérios de Aceite

1. ✅ Campo "Data/Prazo" exibe um calendário ao ser clicado
2. ✅ Data selecionada é formatada como dd/mm/yyyy
3. ✅ Data é persistida no banco como string (não quebra estrutura atual)
4. ✅ Se nenhuma data for selecionada, usa data atual como fallback
5. ✅ Calendário é responsivo e funcional em mobile
6. ✅ Visual consistente com o restante da aplicação
7. ✅ Sem erros no console do navegador
8. ✅ Funcionalidade de adicionar tarefa continua funcionando normalmente

---

## 📚 Referências

- [react-datepicker - Documentação Oficial](https://reactdatepicker.com/)
- [react-datepicker - GitHub](https://github.com/Hacker0x01/react-datepicker)
- Formato de data brasileiro: `toLocaleDateString('pt-BR')`

---

## ⚠️ Observações Importantes

- **NÃO alterar o schema do banco de dados** - a data continua sendo string
- **NÃO quebrar a funcionalidade de data padrão** - se vazio, usar data atual
- **TESTAR a persistência** - confirmar que a string está no formato correto
- **MANTER a simplicidade** - não adicionar validações complexas nesta task

---

## 🔄 Fluxo de Finalização (Executado pelo PO)

Quando o agente DEV concluir todas as etapas:
1. Informar ao PO que a task está pronta
2. PO irá validar se:
   - [ ] Todos os itens do checklist foram marcados
   - [ ] Pull Request foi criado corretamente
   - [ ] Código está implementado conforme especificação
   - [ ] Critérios de aceite foram atendidos
3. PO fará:
   - [ ] Revisão do PR no GitHub
   - [ ] Validação funcional (se possível)
   - [ ] Merge do PR para `bia-desafio-agosto`
   - [ ] Remoção do worktree: `git worktree remove .worktrees/007-feat-calendario`
   - [ ] Mover task para `.kiro/tasks/done/`
   - [ ] Commit e push da finalização

---

**Task criada em:** $(date +%d/%m/%Y)  
**Criada por:** PO

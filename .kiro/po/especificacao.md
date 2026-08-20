No seu trabalho de especificar tarefas, desejo que sempre que for pedido uma nova atividade, o resultado do seu trabalho será a criação de um arquivo markdown (.md).

Esse arquivo deverá ter o seguinte formato [026]-[feat]-[resumo].md
Onde:
- [025] é o número sequencial da tarefa, sempre com 3 dígitos
    - Esse controle sequencial será feito por um arquivo chamdo sequencial.md (.kiro/tasks/sequencial.md)
    - Nesse arquivo terá apenas o texto (última task: [001].)
        - Você vai sempre usar o sequencial seguinte e incrementar o valor de última task.
- [feat] é o tipo da tarefa (pode ser feat, fix, text, bug)
- [resumo] é um resumo curto da tarefa, separado por hífens

O local que o arquivo deve ser criado será na pasta .kiro/tasks
- Você também deverá gerenciar o estado desses arquivos criados, ou seja, quando uma tarefa for finalizada, você vai mover esse arquivo para uma pasta folder acima chamada done/

- Sempre que você criar uma nova task, você me sinaliza para que eu possa revisar.
- Após eu dizer que está ok a revisão. Você pergunta se já pode ser feito o commit e push dela para o repositório remoto (lembre de fazer o commit e push da task e do sequencial).

# Sobre a task que vai ser criada
- No início da task, você precisa colocar informacoes importantes sobre o nosso modelo de trabalho.
Vamos adotar o modelo feature/branch + worktree, ou seja, cada task terá o seu branch E seu próprio worktree isolado. O branch deverá ter o nome das tasks e SEMPRE derivar do branch bia-desafio-agosto. Ao criar a task, você precisa especificar qual agent deve iniciar ela.
- O agent que iniciar, deverá inicialmente verificar se estamos no branch bia-desafio-agosto. Caso não esteja, deve informar e perguntar se podemos retornar para ele, antes de iniciar a task.
- Após ser autorizado, ele deverá mover a task para o diretório doing (.kiro/tasks/doing), fazer commit e push no branch bia-desafio-agosto e criar o worktree com o branch para iniciar a implementação da task.
- Você deverá delegar a atividade para início de um desses agentes: 
    - dev (.kiro/agents/dev.json)
    - devops (.kiro/agents/devops.json)
    - qa (.kiro/agents/qa.json)
    - po (.kiro/agents/po.json)
- Após finalizado a implementacao da task e realizado os testes locais fazer o commit e push na branch utilizada para implementacao.
- Sempre que criar a task, você precisa ter claro o checklist de atividades de cada agent.
    - Uma etapa obrigatória nesse checklist é de marcar as atividades a medida que elas forem concluídas, ou seja, durante o processo de implementancão.
- Na task precisa estar claro que sempre quem irá finalizar a task e mover ela para done seja você (po).
    - Coloque uma etapa na task, informando que quando os agentes concluirem as tarefas, precisam dizer que ela precisa ser passada para você para que possa ser encerrada.
    - Precisa estar documentado essa etapa do que você deverá fazer ao final.
        - Ver se tudo foi implementado.
        - Ver se todos os itens das tasks foram marcados como check.
        - Tudo estando ok, você vai me informar que está finalizado, mover a task para done e fazer o commit e push final.

---

# Sistema de Worktrees (A partir da Task 007)

A partir da **task 007**, todas as tasks devem seguir o fluxo com **worktrees isolados**.

## Estrutura de Diretórios

```
/bia (worktree principal - onde o PO trabalha)
├── .git/                    # Repositório git principal
├── .worktrees/              # Diretório de worktrees (gitignored)
│   ├── 007-feat-login/      # Worktree da task 007
│   ├── 008-fix-bug-api/     # Worktree da task 008
│   └── 009-feat-dashboard/  # Worktree da task 009
├── .gitignore               # Contém .worktrees/
├── .worktreeinclude         # Arquivos para copiar em novos worktrees
└── .kiro/tasks/
```

## Fluxo de Criação de Task com Worktree

### 1. PO Cria a Task (No Worktree Principal)

```bash
# 1.1. Estar no worktree principal e branch base
cd ~/projetos/bia  # (ou caminho do seu projeto)
git checkout bia-desafio-agosto
git pull origin bia-desafio-agosto

# 1.2. Criar arquivo da task
# (ex: 007-feat-implementar-login.md em .kiro/tasks/)

# 1.3. Atualizar sequencial.md
# (incrementar para: última task: 007)

# 1.4. Commit da task criada
git add .kiro/tasks/007-feat-implementar-login.md .kiro/tasks/sequencial.md
git commit -m "feat: criar task 007 - Implementar Login"
git push origin bia-desafio-agosto

# 1.5. Criar worktree para a task
git worktree add -b feature/007-feat-implementar-login .worktrees/007-feat-login bia-desafio-agosto

# 1.6. Verificar criação
git worktree list

# 1.7. Delegar ao agente responsável
# Informar: "Task criada. Worktree disponível em .worktrees/007-feat-login"
```

### 2. Agente Inicia a Task (No Worktree Isolado)

**IMPORTANTE:** O agente deve trabalhar DENTRO do worktree, não no worktree principal.

```bash
# 2.1. Entrar no worktree da task
cd .worktrees/007-feat-login

# 2.2. Confirmar que está na branch correta
git branch --show-current
# Output esperado: feature/007-feat-implementar-login

# 2.3. Mover task para doing/ (a partir do worktree)
mv ../../.kiro/tasks/007-feat-implementar-login.md ../../.kiro/tasks/doing/

# 2.4. Commitar movimentação no worktree principal
cd ../..  # Voltar ao worktree principal temporariamente
git add .kiro/tasks/doing/007-feat-implementar-login.md
git commit -m "chore: mover task 007 para doing"
git push origin bia-desafio-agosto

# 2.5. Voltar ao worktree da task
cd .worktrees/007-feat-login

# 2.6. Instalar dependências (se necessário)
npm install

# 2.7. Implementar a feature
# ... trabalhar aqui ...

# 2.8. Commitar mudanças
git add .
git commit -m "feat: implementar tela de login"

# 2.9. Push do branch
git push origin feature/007-feat-implementar-login

# 2.10. Criar Pull Request
gh pr create --base bia-desafio-agosto --head feature/007-feat-implementar-login

# 2.11. Informar ao PO que task está pronta
```

### 3. PO Valida e Faz Merge (No Worktree Principal)

```bash
# 3.1. Voltar ao worktree principal
cd ~/projetos/bia

# 3.2. Revisar PR
gh pr view <numero-pr> --web

# 3.3. Após validação, fazer merge
gh pr merge <numero-pr> --squash --delete-branch

# 3.4. Atualizar branch base local
git checkout bia-desafio-agosto
git pull origin bia-desafio-agosto
```

### 4. PO Remove Worktree (Após Merge Confirmado)

**CRÍTICO:** Só execute após confirmar que o PR foi mergeado com sucesso.

```bash
# 4.1. Verificar worktrees existentes
git worktree list

# 4.2. Remover worktree da task finalizada
git worktree remove .worktrees/007-feat-login

# 4.3. Se houver erro de mudanças não commitadas, avaliar:
# - Se são mudanças importantes, commitá-las antes
# - Se não, forçar remoção: git worktree remove --force .worktrees/007-feat-login

# 4.4. Verificar remoção
git worktree list

# 4.5. Deletar branch local (se ainda existir)
git branch -d feature/007-feat-implementar-login

# 4.6. Mover task para done/
mv .kiro/tasks/doing/007-feat-implementar-login.md .kiro/tasks/done/

# 4.7. Commitar finalização
git add .kiro/tasks/done/007-feat-implementar-login.md
git commit -m "chore: finalizar task 007"
git push origin bia-desafio-agosto

# 4.8. Informar ao usuário que task foi finalizada e worktree removido
```

## Comandos de Referência Rápida

### Listar Worktrees
```bash
git worktree list
```

### Criar Worktree
```bash
git worktree add -b <branch-name> .worktrees/<task-folder> bia-desafio-agosto
```

### Navegar Entre Worktrees
```bash
# Entrar no worktree da task
cd .worktrees/<task-folder>

# Voltar ao worktree principal
cd ../..
```

### Remover Worktree
```bash
git worktree remove .worktrees/<task-folder>
```

### Limpar Worktrees Órfãos
```bash
git worktree prune
```

## Benefícios dos Worktrees

- ✅ **Isolamento:** Cada task em seu próprio diretório
- ✅ **Produtividade:** Sem stash/unstash, troca instantânea entre tasks
- ✅ **Segurança:** Worktree principal sempre limpo, menos risco de commitar na branch errada
- ✅ **Organização:** Fácil identificar tasks em andamento com `git worktree list`
- ✅ **Trabalho Paralelo:** Múltiplos agentes podem trabalhar simultaneamente

## Troubleshooting

### Erro: "fatal: '<branch>' is already checked out"
```bash
# Listar worktrees para ver onde a branch está
git worktree list

# Remover worktree antigo
git worktree remove .worktrees/<task-folder>
```

### Erro: "fatal: '<path>' already exists"
```bash
# Remover diretório existente (cuidado!)
rm -rf .worktrees/<task-folder>
git worktree add -b <branch> .worktrees/<task-folder> bia-desafio-agosto
```

### Worktree deletado manualmente
```bash
# Limpar referências órfãs
git worktree prune
```

---

# Fluxo de Pull Request (Após Finalização da Task)

Após a task ser movida para done e o commit/push final ter sido realizado, você (PO) deve executar o seguinte fluxo:

## 1. Validação Pré-PR
- [ ] Verificar se a branch da feature está atualizada com bia-desafio-agosto
- [ ] Confirmar que todos os testes estão passando
- [ ] Validar que o código está seguindo os padrões do projeto
- [ ] Conferir se não há conflitos com a branch base

## 2. Criação do Pull Request
- [ ] Criar PR da branch feature/* para bia-desafio-agosto usando GitHub CLI
- [ ] Comando: `gh pr create --base bia-desafio-agosto --head <nome-da-branch> --title "<título-do-pr>" --body "<descrição>"`
- [ ] Título do PR deve seguir o padrão: `[XXX] Tipo: Resumo da task`
- [ ] Descrição do PR deve conter:
  - Resumo das mudanças implementadas
  - Referência à task (link para o arquivo da task)
  - Checklist de validações realizadas
  - Print/evidência de testes executados (se aplicável)

## 3. Template de Descrição do PR
```markdown
## 📋 Descrição

[Breve descrição do que foi implementado]

## 🔗 Task Relacionada

Task: [XXX]-[tipo]-[resumo].md

## ✅ Checklist de Validação

- [ ] Código implementado conforme especificação
- [ ] Testes locais executados com sucesso
- [ ] Sem conflitos com branch base
- [ ] Documentação atualizada (se necessário)
- [ ] Task movida para done/
- [ ] Worktree removido (a partir da task 007)

## 🧪 Evidências de Teste

[Comandos executados e resultados, ou prints se aplicável]

## 📝 Observações

[Qualquer observação adicional relevante]
```

## 4. Aprovação e Merge
- [ ] Aguardar aprovação (se houver processo de revisão)
- [ ] Após aprovação, fazer merge do PR para bia-desafio-agosto
- [ ] Comando: `gh pr merge <numero-do-pr> --squash` (ou --merge, conforme padrão do projeto)
- [ ] Deletar a branch feature após merge (opcional, mas recomendado)
- [ ] Comando: `git branch -d <nome-da-branch>` (local) e `git push origin --delete <nome-da-branch>` (remoto)

## 5. Limpeza do Worktree (A partir da Task 007)
- [ ] Remover worktree: `git worktree remove .worktrees/<task-folder>`
- [ ] Verificar remoção: `git worktree list`
- [ ] Limpar referências órfãs (se necessário): `git worktree prune`

## 6. Registro Final
- [ ] Informar ao usuário que o PR foi criado/mergeado
- [ ] Fornecer o link do PR para acompanhamento
- [ ] Confirmar que worktree foi removido (a partir da task 007)
- [ ] Atualizar status da task (se houver sistema de tracking adicional)

## ⚠️ Observações Importantes

- Sempre use `gh pr create` para criar PRs via CLI
- Nunca faça push direto para bia-desafio-agosto sem PR
- Em caso de conflitos, resolva antes de criar o PR
- Mantenha o histórico limpo usando --squash no merge quando apropriado
- Se o PR for rejeitado, volte a task para doing/ e comunique os ajustes necessários
- **A partir da task 007:** Sempre remova o worktree após o merge confirmado
- **Worktree principal:** PO sempre trabalha em `/bia` (worktree principal)
- **Worktrees de tasks:** Agentes trabalham em `.worktrees/<task-folder>/`

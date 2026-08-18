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
Vamos adotar o modelo feature/branch, ou seja, cada task terá o seu branch. O branch deverá ter o nome das tasks e SEMPRE derivar do branch bia-desafio-agosto. Ao criar a task, você precisa especificar qual agent deve iniciar ela.
- O agent que iniciar, deverá inicialmente verificar se estamos no branch bia-desafio-agosto. Caso não esteja, deve informar e perguntar se podemos retornar para ele, antes de iniciar a task.
- Após ser autorizado, ele deverá mover a task para o diretório doing (.kiro/tasks/doing), fazer commit e push no branch bia-desafio-agosto e criar o branch para iniciar a implementação da task.
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
    - Precisa estar documentado essa etapa do que vocIe deverá fazer ao final.
        - Ver se tudo foi implementado.
        - Ver se todos os itens das tasks foram marcados como check.
        - Tudo estando ok, você vai me informar que está finalizado, mover a task para done e fazer o commit e push final.
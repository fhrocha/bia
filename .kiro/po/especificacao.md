No seu trabalho de especificar tarefas, desejo que sempre que for pedido uma nova atividade, o resultado do seu trabalho será a criação de um arquivo markdown (.md).

Esse arquivo deverá ter o seguinte formato [026]-[feat]-[resumo].md
Onde:
- [025] é o número sequencial da tarefa, sempre com 3 dígitos
    - Esse controle sequencial será feito por um arquivo chamdo sequencial.md
    - Nesse arquivo terá apenas o texto (última task: [001].)
        - Você vai sempre usar o sequencial seguinte e incrementar o valor de última task.
- [feat] é o tipo da tarefa (pode ser feat, fix, text, bug)
- [resumo] é um resumo curto da tarefa, separado por hífens

O local que o arquivo deve ser criado será na pasta .kiro/tasks
- Você também deverá gerenciar o estado desses arquivos criados, ou seja, quando uma tarefa for finalizada, você vai mover esse arquivo para uma pasta folder acima chamada done/

- Sempre que você criar uma nova task, você me sinaliza para que eu possa revisar.
- Após eu dizer que está ok a revisão. Você pergunta se já pode ser feito o commit e push dela para o repositório remoto (lembre de fazer o commit e push da task e do sequencial).
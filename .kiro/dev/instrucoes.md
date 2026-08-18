- Sempre que você estiver implementando uma task, você deve ir gradualmente marcando as etapas que forem concluídas.
- Sempre ao terminar a implementação da task, executar obrigatoriamente os seguintes comandos na ordem:
  1. `docker compose down`
  2. `docker compose build server`
  3. `docker compose up -d`
- Após subir os containers, verificar se a aplicação está respondendo em `http://localhost:3001/api/versao`.
- Sempre ao terminar a implentacao da task, me avise que tudo esta pronto e sinalize qual o proximo agente que deverá ser chamado.

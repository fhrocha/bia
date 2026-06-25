versao=$(git rev-parse HEAD | cut -c 1-7)
echo TAG=$versao > .env
docker-compose -f compose-eb.yml config >> compose-eb-dev.yml
mv compose-eb-dev.yml docker-compose.yml
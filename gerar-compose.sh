versao=$(git rev-parse HEAD | cut -c 1-7)
echo TAG=$versao > .env
#docker compose -f compose-eb.yml config --no-normalize >> compose-eb-dev.yml
docker compose -f compose-build-eb.yml config --no-normalize >> compose-eb-dev.yml
gsed -i '/^name:/d' compose-eb-dev.yml
gsed -i '/bia:$/a \    env_file: .env' compose-eb-dev.yml
gsed -i 's|/Users/fhrocha/formacaoaws/bia|.|g' compose-eb-dev.yml
mv compose-eb-dev.yml docker-compose.yml
source utils.sh

versao=$(git rev-parse HEAD | cut -c 1-7)
aws ecr get-login-password --region us-east-1 --profile formacaoaws | docker login --username AWS --password-stdin 305068201474.dkr.ecr.us-east-1.amazonaws.com
checar_ultimo_commando
docker build --platform linux/amd64 -t bia .
#docker compose -f compose-build-eb.yml build bia
docker tag bia:latest 305068201474.dkr.ecr.us-east-1.amazonaws.com/ecr-bia:$versao
docker push 305068201474.dkr.ecr.us-east-1.amazonaws.com/ecr-bia:$versao
checar_ultimo_commando
rm .env
./gerar-compose.sh
checar_ultimo_commando
rm bia-versao-*zip
zip -r bia-versao.zip docker-compose.yml
git checkout docker-compose.yml
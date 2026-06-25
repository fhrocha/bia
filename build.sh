versao=$(git rev-parse HEAD | cut -c 1-7)
aws ecr get-login-password --region us-east-1 --profile formacaoaws | docker login --username AWS --password-stdin 305068201474.dkr.ecr.us-east-1.amazonaws.com
docker build --platform linux/amd64 -t bia .
docker tag bia:latest 305068201474.dkr.ecr.us-east-1.amazonaws.com/ecr-bia:$versao
docker push 305068201474.dkr.ecr.us-east-1.amazonaws.com/ecr-bia:$versao
rm .env
./gerar-compose.sh
rm bia-versao-*zip
zip -r bia-versao.zip docker-compose.yml
git checkout docker-compose.yml
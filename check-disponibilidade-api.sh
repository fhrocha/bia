url="http://bia-alb-1323241707.us-east-1.elb.amazonaws.com:3001"
docker build -t check_disponibilidade_api -f Dockerfile_checkdisponibilidade .
docker run --rm -ti -e URL=$url check_disponibilidade_api

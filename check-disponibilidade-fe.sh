url="http://bia-alb-1149604023.us-east-1.elb.amazonaws.com"
docker build -t check_disponibilidade_fe -f Dockerfile_checkdisponibilidade .
docker run --rm -ti -e URL=$url check_disponibilidade_fe

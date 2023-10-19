aws ecr get-login-password --region us-gov-west-1 | docker login --username AWS --password-stdin 053633994311.dkr.ecr.us-gov-west-1.amazonaws.com

docker build -t dataprepper .

docker tag dataprepper:latest 053633994311.dkr.ecr.us-gov-west-1.amazonaws.com/dataprepper:latest

docker push 053633994311.dkr.ecr.us-gov-west-1.amazonaws.com/dataprepper:latest

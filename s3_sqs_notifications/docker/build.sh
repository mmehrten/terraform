#! /bin/sh

set -e

read -p "ECR namespace name ({account_id}.dkr.ecr.{region}.amazonaws.com): " ECR_NAME

aws ecr get-login-password | docker login --username AWS --password-stdin "${ECR_NAME}"

docker build -t dataprepper .

docker tag dataprepper:latest "${ECR_NAME}"/dataprepper:latest

docker push "${ECR_NAME}"/dataprepper:latest

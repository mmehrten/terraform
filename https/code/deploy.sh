REGISTRY=$1
aws ecr get-login-password --region us-gov-west-1 | docker login --username AWS --password-stdin $REGISTRY
docker buildx build --platform=linux/amd64 -t $REGISTRY/https-demo:latest .
docker push $REGISTRY/https-demo:latest

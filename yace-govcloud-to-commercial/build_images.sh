#!/bin/bash
set -e

ACCOUNT_ID=$1
REGION=$2

if [ -z "${ACCOUNT_ID}" ] || [ -z "${REGION}" ]; then
    echo "Usage: "
    echo "./build_images.sh ACCOUNT_ID REGION"
    echo "./build_images.sh 012345678910 us-east-1"
    exit 1
fi

aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
cd docker/

echo "Building yace image"

DOCKER_DEFAULT_PLATFORM="linux/amd64" docker build -t "yace" .
docker tag "yace:latest" "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/yace:latest"
docker push "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/yace:latest"


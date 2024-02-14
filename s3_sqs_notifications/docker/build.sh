#! /bin/sh

set -e

ECR_NAME="$1"
if [ -z "${ECR_NAME}" ]; then
    read -p "ECR namespace name ({account_id}.dkr.ecr.{region}.amazonaws.com): " ECR_NAME
fi

aws ecr get-login-password | docker login --username AWS --password-stdin "${ECR_NAME}"

docker build \
    -t dataprepper \
    -t "${ECR_NAME}"/dataprepper:cvesuppress \
    -t "${ECR_NAME}"/dataprepper:suppress-CVE-abc \
    -t "${ECR_NAME}"/dataprepper:latest \
    .

# docker tag dataprepper:latest "${ECR_NAME}"/dataprepper:latest,cvesuppress,example

docker push "${ECR_NAME}"/dataprepper --all-tags

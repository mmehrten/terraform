#!/bin/bash
set -e

REGION=$1

if [ -z "${REGION}" ]; then
    echo "Usage: "
    echo "./access.sh REGION"
    echo "./access.sh us-east-1"
    exit 1
fi

export AWS_DEFAULT_REGION="${REGION}"

for cluster in `aws ecs list-clusters | jq '.clusterArns[]' | tr -d '"' | cut -d"/" -f 2`; do
    # echo $cluster
    for service in `aws ecs list-services --cluster "${cluster}" | jq '.serviceArns[]' | tr -d '"' | cut -d"/" -f 3`; do
        # echo $service
        for task in `aws ecs list-tasks --cluster "${cluster}" --service "${service}" | jq '.taskArns[]' | tr -d '"' | cut -d"/" -f 3`; do
            # echo $task
            echo "Run command:"
            echo "aws ecs execute-command --region ${REGION} --cluster ${cluster} --container odbc --command "/bin/bash" --interactive --task ${task}";
        done;
    done;
done;
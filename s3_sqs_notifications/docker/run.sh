#!/bin/bash
set -e

aws s3 cp "${PIPELINES_S3_BUCKET}/dataprepper/pipelines/*" ./pipelines/

bin/data-prepper
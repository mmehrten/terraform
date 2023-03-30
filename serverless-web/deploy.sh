WEB_BUCKET="web-zwy2.us-gov-west-1.s3.web"
REGION="us-gov-west-1"

aws s3 cp --recursive static/ "s3://${WEB_BUCKET}/static/" --region $REGION

import json
import boto3
import os
from botocore.client import Config

endpoint_ip = os.environ["ENDPOINT_IP"]
region = os.environ["REGION"]
config = Config(connect_timeout=2, read_timeout=2, retries={'max_attempts': 0})
session = boto3.session.Session()
s3 = session.client(
    "s3", 
    endpoint_url=f"https://{endpoint_ip}/", 
    region_name=region, 
    use_ssl=True, 
    verify=False,
    config=config,
)

def lambda_handler(event, context):
    s3.list_buckets()
    return {
        'statusCode': 200,
        'body': json.dumps({
            "message": "No error in listing buckets via endpoint IP",
            "endpoint": endpoint_ip,
            "region": region,
        })
    }


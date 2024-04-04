import functools
import json
import os
import boto3
import requests 

import boto3
from opensearchpy import (
    AWSV4SignerAuth,
    NotFoundError,
    OpenSearch,
    RequestsHttpConnection,
)
from dataset_loader import handle_sqs_event

host = os.environ["OPENSEARCH_ENDPOINT"]
port = 443
region = os.environ["AWS_REGION"]
credentials = boto3.Session().get_credentials()
auth = AWSV4SignerAuth(credentials, region)
service = 'es'
headers = {"Content-Type": "application/json"}


@functools.lru_cache(maxsize=10)
def get_client(endpoint: str = host, username: str = None, password: str = None):
    auth_var = (username, password) if username and password else auth
    client = OpenSearch(
        hosts=[f"{endpoint}:{port}"],
        http_auth=auth_var,
        use_ssl=True,
        verify_certs=True,
        connection_class=RequestsHttpConnection,
    )
    return client


def create_index(client, event):
    index_name = event["index_name"]
    try:
        return client.indices.get(index_name)
    except NotFoundError:
        return client.indices.create(index_name, body=event["body"])


def create_template(client, event):
    return client.indices.put_index_template(name=event["name"], body=event["body"])


def create_document(client, event):
    return client.index(index=event["index_name"], body=event["body"], refresh=True)


def run_search(client, event):
    return client.search(index=event["index_name"], body=event["body"], refresh=True)


def create_role(client, event):
    return client.security.create_role(
        role=event["role_name"], body=event["body"], refresh=True
    )


def create_role_mapping(client, event):
    return client.security.create_role_mapping(
        role=event["role_name"], body=event["body"]
    )


def misc(event):
    r = requests.request(event["method"], 'https://' + event.get("endpoint", host) + event["path"], auth=auth, json=event["body"], headers=headers)
    print(r.text)
    r.raise_for_status()
    try:
        return r.json()
    except:
        return r.text


def _handler(event, context):
    client = get_client(
        event.get("endpoint", host), event.get("username"), event.get("password")
    )
    if event.get("type") == "index":
        return create_index(client, event)
    elif event.get("type") == "doc":
        return create_document(client, event)
    elif event.get("type") == "search":
        return run_search(client, event)
    elif event.get("type") == "role":
        return create_role(client, event)
    elif event.get("type") == "role_mapping":
        return create_role_mapping(client, event)
    elif event.get("type") == "template":
        return create_template(client, event)
    elif event.get("Records"):
        return handle_sqs_event(client, event, context)
    return misc(event)


def handler(event, context):
    print(f"Event: {event}")
    resp = _handler(event, context)
    print(f"Response: {resp}")
    return resp


if __name__ == "__main__":
    event = {
        "Records": [
            {
            "eventVersion": "2.1",
            "eventSource": "aws:s3",
            "awsRegion": "us-east-1",
            "eventTime": "2024-04-03T21:58:48.992Z",
            "eventName": "ObjectCreated:CompleteMultipartUpload",
            "userIdentity": {
                "principalId": "AWS:AROAVAMHXGQR454LXS6H6:mmehrten-Isengard"
            },
            "requestParameters": {
                "sourceIPAddress": "207.229.152.94"
            },
            "responseElements": {
                "x-amz-request-id": "P6VASMHFTZ76BCZS",
                "x-amz-id-2": "3MdxcG2MIAYUKb5KSK3T4NS8BOJ1zs/ulVi5emqhgY/4bWKNdLttThlgl+uDRjRxClcW5wu3YseJdGZmTMcq1Q7aCX46ChoO"
            },
            "s3": {
                "s3SchemaVersion": "1.0",
                "configurationId": "tf-s3-queue-20240403205417044800000001",
                "bucket": {
                "name": "os-zwy2.us-east-1.s3.nlp",
                "ownerIdentity": {
                    "principalId": "A2418CIUEEGAZL"
                },
                "arn": "arn:aws:s3:::os-zwy2.us-east-1.s3.nlp"
                },
                "object": {
                "key": "englishText_0_10000.txt",
                "size": 22650880,
                "eTag": "df61ef28c4d4e721b274bfeaf0fa9c4f-3",
                "sequencer": "00660DD115001B5323"
                }
            }
            }
        ]
        }
    handler(event, {})
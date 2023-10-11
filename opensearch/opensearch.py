import boto3
from opensearchpy import (
    AWSV4SignerAuth,
    NotFoundError,
    OpenSearch,
    RequestsHttpConnection,
)
import os
import json


host = os.environ["OPENSEARCH_ENDPOINT"]
port = 443
region = os.environ["AWS_REGION"]

# call AssumeRole
credentials = boto3.Session().get_credentials()
auth = AWSV4SignerAuth(credentials, region)

client = OpenSearch(
    hosts=[f"{host}:{port}"],
    http_auth=auth,
    use_ssl=True,
    verify_certs=True,
    connection_class=RequestsHttpConnection,
)


def create_index(event):
    index_name = event["index_name"]
    try:
        return client.indices.get(index_name)
    except NotFoundError:
        return client.indices.create(index_name, body=event["body"])


def create_template(event):
    return client.indices.put_index_template(name=event["name"], body=event["body"])


def create_document(event):
    return client.index(index=event["index_name"], body=event["body"], refresh=True)


def run_search(event):
    return client.search(index=event["index_name"], body=event["body"], refresh=True)


def create_role(event):
    return client.security.create_role(
        role=event["role_name"], body=event["body"], refresh=True
    )


def create_role_mapping(event):
    return client.security.create_role_mapping(
        role=event["role_name"], body=event["body"]
    )


def handler(event, context):
    if event["type"] == "index":
        return create_index(event)
    elif event["type"] == "doc":
        return create_document(event)
    elif event["type"] == "search":
        return run_search(event)
    elif event["type"] == "role":
        return create_role(event)
    elif event["type"] == "role_mapping":
        return create_role_mapping(event)
    elif event["type"] == "template":
        return create_template(event)
    raise NotImplementedError(json.dumps(event))

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
    return r.json()


def handler(event, context):
    client = get_client(
        event.get("endpoint", host), event.get("username"), event.get("password")
    )
    if event["type"] == "index":
        return create_index(client, event)
    elif event["type"] == "doc":
        return create_document(client, event)
    elif event["type"] == "search":
        return run_search(client, event)
    elif event["type"] == "role":
        return create_role(client, event)
    elif event["type"] == "role_mapping":
        return create_role_mapping(client, event)
    elif event["type"] == "template":
        return create_template(client, event)
    return misc(event)

import functools
import os
import uuid
import time

import boto3
from opensearchpy import (
    AWSV4SignerAuth,
    NotFoundError,
    OpenSearch,
    RequestsHttpConnection,
)
import datetime

port = 443
region = os.environ["AWS_REGION"]

# call AssumeRole
credentials = boto3.Session().get_credentials()
auth = AWSV4SignerAuth(credentials, region)


@functools.lru_cache(maxsize=10)
def get_client(endpoint: str, username: str = None, password: str = None):
    auth_var = (username, password) if username and password else auth
    client = OpenSearch(
        hosts=[f"{endpoint}:{port}"],
        http_auth=auth_var,
        use_ssl=True,
        verify_certs=True,
        connection_class=RequestsHttpConnection,
    )
    return client


docs = [
    {
        "endpoint": "vpc-os-zwy2-us-gov-west-1-demo-mnfhpkqgmzrlgwkqh2kulkfnqy.us-gov-west-1.es.amazonaws.com",
        "index_name": "ss4o_demo-cluster",
        "body": {"hello": "world"},
    },
    {
        "endpoint": "vpc-os-rgx1-us-gov-west-1-user-jstif5ks2jj5qzvneoxtjaxs3q.us-gov-west-1.es.amazonaws.com",
        "index_name": "ss4o_user-cluster",
        "body": {"hello": "world"},
    },
]


def handler(e, c):
    for _ in range(0, 30):
        for event in docs:
            client = get_client(
                event["endpoint"], event.get("username"), event.get("password")
            )
            event["body"]["timestamp"] = str(datetime.datetime.now())
            client.index(
                index=event["index_name"],
                body=event["body"],
                id=str(uuid.uuid4()),
            )
        time.sleep(1)
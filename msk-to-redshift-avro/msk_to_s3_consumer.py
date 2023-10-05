import base64
import datetime
import functools
import io
import json
import os
import time

import avro.io
import avro.schema
import boto3
from botocore.config import Config

config = Config(connect_timeout=2, read_timeout=2, retries={"max_attempts": 0})
glue = boto3.client("glue", config=config)
s3 = boto3.client("s3", config=config)
redshift = boto3.client("redshift-data", config=config)
REGISTRY_NAME = os.environ["REGISTRY_NAME"]
BUCKET_NAME = os.environ["BUCKET_NAME"]
CLUSTER_NAME = os.environ["CLUSTER_NAME"]
DATABASE_NAME = os.environ["DATABASE_NAME"]
USER_NAME = os.environ["USER_NAME"]
REGION = os.environ["AWS_REGION"]
REDSHIFT_IAM_ROLE = os.environ["REDSHIFT_IAM_ROLE"]


@functools.lru_cache(maxsize=32)
def _get_schema(registry_name: str, stream_name: str) -> avro.schema.Schema:
    """Get an Avro schema from the registry by stream name.

    :param stream_name: The stream name for the schema to request
    :returns: The Avro schema object
    """
    schema_resp = glue.get_schema_version(
        SchemaId={"RegistryName": registry_name, "SchemaName": stream_name},
        SchemaVersionNumber={"LatestVersion": True},
    )
    schema = schema_resp["SchemaDefinition"]
    return avro.schema.parse(schema)


def _avro_to_json(registry_name: str, stream_name: str, data: bytes) -> str:
    schema = _get_schema(registry_name, stream_name)
    data_bytes = io.BytesIO(data)
    decoder = avro.io.BinaryDecoder(data_bytes)
    reader = avro.io.DatumReader(schema)
    decoded = reader.read(decoder)
    return json.dumps(decoded)


def _execute(statement: str, wait_until_complete=True):
    resp = redshift.execute_statement(
        ClusterIdentifier=CLUSTER_NAME,
        Database=DATABASE_NAME,
        DbUser=USER_NAME,
        Sql=statement,
        StatementName=str(time.time()),
        WithEvent=False,
    )
    print(f"Resp: {resp}")
    while True:
        state_resp = redshift.describe_statement(Id=resp["Id"])
        state = state_resp["Status"]
        if state == "FINISHED" or not wait_until_complete:
            return True
        if state in ("FAILED", "ABORTED"):
            raise RuntimeError(str(state_resp))
        time.sleep(2)


def handler(event, context):
    try:
        print(json.dumps(event))
        for records in event["records"].values():
            results = []
            topic = None
            for record in records:
                topic = record["topic"]
                record["headers"] = json.dumps(record["headers"])
                record["value_json"] = _avro_to_json(
                    REGISTRY_NAME, topic, base64.b64decode(record["value"])
                )
                results.append(json.dumps(record))
            now = datetime.datetime.now()
            key = (
                f"{topic}/{now.year}/{now.month}/{now.day}/{int(now.timestamp())}.jsonl"
            )
            print(f"Writing s3://{BUCKET_NAME}/{key}")
            s3.put_object(Bucket=BUCKET_NAME, Body="\n".join(results), Key=key)
            _execute(
                f"CREATE TABLE IF NOT EXISTS {topic} (topic VARCHAR, \"partition\" BIGINT, \"offset\" BIGINT, timestamp BIGINT, timestampType CHAR, key VARCHAR(max), value VARCHAR(max), value_json VARCHAR(max), headers VARCHAR(max));"
            )
            _execute(
                f"COPY {topic} FROM 's3://{BUCKET_NAME}/{key}' IAM_ROLE '{REDSHIFT_IAM_ROLE}' REGION '{REGION}' format as json 'auto';",
                wait_until_complete=False,
            )
        return json.dumps({"success": True})
    except Exception as e:        
        raise RuntimeError(
            json.dumps(
                {
                    "success": False,
                    "error_msg": f"Error processing Lambda event. Error: {e}. Event: {event}",
                }
            )
        )

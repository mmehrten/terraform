import functools
import io
import json
import os

import avro.io
import avro.schema
import boto3
from botocore.config import Config

config = Config(connect_timeout=2, read_timeout=2, retries={"max_attempts": 0})
glue = boto3.client("glue", config=config)


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


def _avro_to_json(registry_name: str, stream_name: str, data: str) -> str:
    """Decode a single Hex-encoded Avro datum using the schema associated with the stream name.

    :param registry_name: The Glue Schema Registry name for the schema
    :param stream_name: The stream name for the data
    :param data: The Hex-encoded Avro binary data
    :returns: A JSON encoded version of the data
    """
    schema = _get_schema(registry_name, stream_name)
    data_bytes = io.BytesIO(bytes.fromhex(data))
    decoder = avro.io.BinaryDecoder(data_bytes)
    reader = avro.io.DatumReader(schema)
    decoded = reader.read(decoder)
    return json.dumps(decoded)


def handler(event, context):
    try:
        results = []
        for registry_name, stream_name, data in event["arguments"]:
            results.append(_avro_to_json(registry_name, stream_name, data))
        return json.dumps(
            {
                "success": True,
                "num_records": event["num_records"],
                "results": results,
            }
        )
    except Exception as e:
        return json.dumps(
            {
                "success": False,
                "error_msg": f"Error processing Lambda event. Error: {e}. Event: {event}",
            }
        )

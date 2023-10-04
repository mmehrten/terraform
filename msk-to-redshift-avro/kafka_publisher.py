import functools
import io
import json
import os

import avro.io
import avro.schema
import boto3
from botocore.config import Config
from kafka import KafkaProducer

config = Config(connect_timeout=2, read_timeout=2, retries={"max_attempts": 0})
glue = boto3.client("glue", config=config)
BROKERS = os.environ["BROKER_STRING"]
producer = KafkaProducer(bootstrap_servers=BROKERS, api_version=(0, 11, 5))


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


def _json_to_avro(registry_name: str, stream_name: str, data: str) -> bytes:
    """Decode a single Hex-encoded Avro datum using the schema associated with the stream name.

    :param registry_name: The Glue Schema Registry name for the schema
    :param stream_name: The stream name for the data
    :param data: The Hex-encoded Avro binary data
    :returns: A JSON encoded version of the data
    """
    schema = _get_schema(registry_name, stream_name)
    writer = avro.io.DatumWriter(schema)
    bytes_writer = io.BytesIO()
    encoder = avro.io.BinaryEncoder(bytes_writer)
    writer.write(json.loads(data), encoder)
    return bytes_writer.getvalue()


def handler(event, context):
    try:
        for registry_name, stream_name, data in event["arguments"]:
            producer.send(stream_name, _json_to_avro(registry_name, stream_name, data))
        producer.flush()
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

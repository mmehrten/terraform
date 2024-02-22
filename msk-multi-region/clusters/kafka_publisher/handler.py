import json

from aws_lambda_powertools import Logger

from kafka_admin import (
    create_acl,
    create_admin_principal,
    create_east_west_tls_principals,
)
from kafka_publisher import produce_conn_test, produce_registry_avro, produce_simple

logger = Logger()


@logger.inject_lambda_context(log_event=True)
def handler(event, context):
    try:
        if event["type"] == "simple_principal_create":
            create_east_west_tls_principals()
        elif event["type"] == "create_admin_principal":
            create_admin_principal(
                bootstrap_servers=event["bootstrap_servers"],
                principal=event["principal"],
                region=event["region"],
            )
        elif event["type"] == "conn_test":
            produce_conn_test()
        elif event["type"] == "registry_avro":
            produce_registry_avro(event)
        elif event["type"] == "create_acl":
            create_acl(**event)
        elif event["type"] == "produce_simple":
            produce_simple(**event)
        else:
            raise NotImplementedError()
        return json.dumps({"success": True})
    except Exception as e:
        raise RuntimeError(
            json.dumps(
                {
                    "success": False,
                    "error_msg": f"Error processing Lambda event. Error: {e}. Event: {event}",
                }
            )
        ) from e

import json
import os
import ssl

from aws_lambda_powertools import Logger
from kafka import KafkaProducer

from json_avro_parsing import _json_to_avro
from token_provider import MSKTokenProvider

logger = Logger()


PLAINTEXT_PORT = 9092
IAM_PORT = 9098
TLS_PORT = 9094
SASL_PORT = 9096
EAST_DOMAIN = "mskzwy2usgoveast1m.7nitq1.c2.kafka.us-gov-east-1.amazonaws.com"
WEST_DOMAIN = "mskzwy2usgovwest1m.tntl4g.c2.kafka.us-gov-west-1.amazonaws.com"
METHODS = [
    "tls",
    "iam",
    # "scram"
]
urls = {}


def generate_urls():
    for method in METHODS:
        for domain in [EAST_DOMAIN, WEST_DOMAIN]:
            if method == "plaintext":
                for i in range(1, 4):
                    yield f"b-{i}", domain, PLAINTEXT_PORT, "nonvpc", method
            if method == "tls":
                for i in range(1, 4):
                    yield f"b-{i}", domain, TLS_PORT, "nonvpc", method
                # if os.environ["AWS_REGION"] in domain:
                #     for i in range(1, 4):
                #         yield f"b-{i}", f"{method}.{domain}", 14000+i, "vpc", method
            if method == "iam":
                for i in range(1, 4):
                    yield f"b-{i}", domain, IAM_PORT, "nonvpc", method
                # if os.environ["AWS_REGION"] in domain:
                #     for i in range(1, 4):
                #         yield f"b-{i}", f"{method}.{domain}", 14000+i, "vpc", method
            if method == "scram":
                for i in range(1, 4):
                    yield f"b-{i}", domain, SASL_PORT, "nonvpc", method
                # if os.environ["AWS_REGION"] in domain:
                #     for i in range(1, 4):
                #         yield f"b-{i}", f"{method}.{domain}", 14000+i, "vpc", method


def generate_producers():
    urls = {}
    for broker, domain, port, vpctype, method in generate_urls():
        url = f"{broker}.{domain}:{port}"
        key = f"{method}{domain}"
        if key not in urls:
            urls[key] = {}
        if vpctype not in urls[key]:
            urls[key][vpctype] = []
        urls[key][vpctype].append(url)
    for key in urls:
        for vpctype in urls[key]:
            bootstrap_servers = ",".join(urls[key][vpctype])
            region = urls[key][vpctype][0].split(".")[-3]
            logger.info(bootstrap_servers)
            if "plaintext" in key:
                yield KafkaProducer(
                    bootstrap_servers=bootstrap_servers, api_version=(0, 11, 5)
                )
            if "tls" in key:
                context = ssl.create_default_context(
                    ssl.Purpose.CLIENT_AUTH, cafile=f"CertificateChain.{region}.pem"
                )
                context.load_cert_chain(
                    certfile=f"Certificate.{region}.pem",
                    keyfile=f"PrivateKey.{region}.pem",
                    password=os.environ["AWS_ACM_CERT_PASS"],
                )
                yield KafkaProducer(
                    bootstrap_servers=bootstrap_servers,
                    security_protocol="SSL",
                    ssl_context=context,
                )
            if "scram" in key:
                yield KafkaProducer(
                    security_protocol="SASL_SSL",
                    sasl_mechanism="SCRAM-SHA-512",
                    sasl_plain_username="demo",
                    sasl_plain_password=os.environ["AWS_ACM_CERT_PASS"],
                    bootstrap_servers=bootstrap_servers,
                )
            if "iam" in key:
                yield KafkaProducer(
                    bootstrap_servers=bootstrap_servers,
                    security_protocol="SASL_SSL",
                    sasl_mechanism="OAUTHBEARER",
                    sasl_oauth_token_provider=MSKTokenProvider(region),
                    request_timeout_ms=1000,
                )


def produce_conn_test():
    for _producer in generate_producers():
        logger.info(f"Producing with: {_producer}")
        _producer.send("conn_testing", json.dumps({"hello": "world"}).encode("utf-8"))
        _producer.flush(timeout=1)
        logger.info(f"Finished with: {_producer}")


def produce_registry_avro(event):
    for _producer in generate_producers():
        logger.info(f"Producing with: {_producer}")
        for registry_name, stream_name, data in event["arguments"]:
            _producer.send(stream_name, _json_to_avro(registry_name, stream_name, data))
        _producer.flush(timeout=1)
        logger.info(f"Finished with: {_producer}")

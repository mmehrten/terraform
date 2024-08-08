from kafka.admin import (
    ACL,
    ACLOperation,
    ACLPermissionType,
    KafkaAdminClient,
    ResourcePattern,
    ResourceType,
    NewPartitions,
    NewTopic,
    ConfigResource,
    ConfigResourceType
)
import json
from aws_msk_iam_sasl_signer import MSKAuthTokenProvider
import requests
from kafka import KafkaProducer, KafkaConsumer
import time

class MSKTokenProvider:
    def __init__(self, region):
        self.region = region

    def token(self):
        token, _ = MSKAuthTokenProvider.generate_auth_token(self.region)
        return token


source_admin = KafkaAdminClient(
    bootstrap_servers="b-1.mskzwy2usgovwest1t.18i5m3.c2.kafka.us-gov-west-1.amazonaws.com:9098,b-3.mskzwy2usgovwest1t.18i5m3.c2.kafka.us-gov-west-1.amazonaws.com:9098,b-2.mskzwy2usgovwest1t.18i5m3.c2.kafka.us-gov-west-1.amazonaws.com:9098",
    security_protocol="SASL_SSL",
    sasl_mechanism="OAUTHBEARER",
    sasl_oauth_token_provider=MSKTokenProvider("us-gov-west-1"),
    request_timeout_ms=1000,
)
target_admin = KafkaAdminClient(
    bootstrap_servers="b-1.mskzwy2usgovwest1s.v1v3mm.c2.kafka.us-gov-west-1.amazonaws.com:9098,b-2.mskzwy2usgovwest1s.v1v3mm.c2.kafka.us-gov-west-1.amazonaws.com:9098,b-3.mskzwy2usgovwest1s.v1v3mm.c2.kafka.us-gov-west-1.amazonaws.com:9098",
    security_protocol="SASL_SSL",
    sasl_mechanism="OAUTHBEARER",
    sasl_oauth_token_provider=MSKTokenProvider("us-gov-west-1"),
    request_timeout_ms=1000,
)
source_produer = KafkaProducer(
    bootstrap_servers="b-1.mskzwy2usgovwest1t.18i5m3.c2.kafka.us-gov-west-1.amazonaws.com:9098,b-3.mskzwy2usgovwest1t.18i5m3.c2.kafka.us-gov-west-1.amazonaws.com:9098,b-2.mskzwy2usgovwest1t.18i5m3.c2.kafka.us-gov-west-1.amazonaws.com:9098",
    security_protocol="SASL_SSL",
    sasl_mechanism="OAUTHBEARER",
    sasl_oauth_token_provider=MSKTokenProvider("us-gov-west-1"),
    request_timeout_ms=1000,
)
target_consumer = KafkaConsumer(
    "ExampleTopic",
    group_id='python',
    bootstrap_servers="b-1.mskzwy2usgovwest1s.v1v3mm.c2.kafka.us-gov-west-1.amazonaws.com:9098,b-2.mskzwy2usgovwest1s.v1v3mm.c2.kafka.us-gov-west-1.amazonaws.com:9098,b-3.mskzwy2usgovwest1s.v1v3mm.c2.kafka.us-gov-west-1.amazonaws.com:9098",
    security_protocol="SASL_SSL",
    sasl_mechanism="OAUTHBEARER",
    sasl_oauth_token_provider=MSKTokenProvider("us-gov-west-1"),
    request_timeout_ms=20000,
)
source_consumer = KafkaConsumer(
    "ExampleTopic",
    group_id='python',
    bootstrap_servers="b-1.mskzwy2usgovwest1t.18i5m3.c2.kafka.us-gov-west-1.amazonaws.com:9098,b-3.mskzwy2usgovwest1t.18i5m3.c2.kafka.us-gov-west-1.amazonaws.com:9098,b-2.mskzwy2usgovwest1t.18i5m3.c2.kafka.us-gov-west-1.amazonaws.com:9098",
    security_protocol="SASL_SSL",
    sasl_mechanism="OAUTHBEARER",
    sasl_oauth_token_provider=MSKTokenProvider("us-gov-west-1"),
    request_timeout_ms=20000,
)


source_admin.list_topics()
target_admin.list_topics()

for message in target_consumer:
    print(message)
    break

for message in source_consumer:
    print(message)
    break

    
{i["topic"]: len(i["partitions"]) for i in source_admin.describe_topics()}
source_admin.create_topics([NewTopic("ExampleTopic", 30, 3)])
target_admin.create_topics([NewTopic("heartbeats", 6, 3)])
source_admin.alter_configs([ConfigResource(ConfigResourceType.TOPIC, "heartbeats", {"retention.ms": 1000*60*30} )])
source_admin.alter_configs([ConfigResource(ConfigResourceType.TOPIC, "ExampleTopic", {"retention.ms": 1000*60*30} )])
source_admin.alter_configs([ConfigResource(ConfigResourceType.TOPIC, "mm2-offset-syncs.mskdest.internal", {"retention.ms": 1000*60*30} )])
source_admin.alter_configs([ConfigResource(ConfigResourceType.TOPIC, "connect-configs-kafka-connect-fargate", {"retention.ms": 1000*60*30} )])
source_admin.delete_topics(["ExampleTopic"])
for i in ("cpc", "msc", "hbc"):
    res = requests.delete(f"http://kafka-connect.msk-zwy2.us-gov-west-1.local:8083/connectors/mm2-{i}")
    print(res)
    print(res.content)
    with open(f"mm2-{i}-iam-auth.json", "r") as f:
        res = requests.put(f"http://kafka-connect.msk-zwy2.us-gov-west-1.local:8083/connectors/mm2-{i}/config", json=json.loads(f.read()))
        print(res)
        print(res.json())
for i in ("cpc", "msc", "hbc"):
    res = requests.get(f"http://kafka-connect.msk-zwy2.us-gov-west-1.local:8083/connectors/mm2-{i}/status")
    print(res.json())


slept = 0
sleeper=5
while slept < 60 * 60 * 3:
    for j in range(0, 100):
        for i in range(0, 100):
            source_produer.send("ExampleTopic", json.dumps({"hello": "world", "outer": j, "inner": i, "for_size": "a" * 512}).encode("utf-8"))
        source_produer.flush(timeout=20)
    time.sleep(sleeper)
    slept += sleeper

aws s3 cp s3://msk-zwy2.us-gov-west-1.configs/connector/mm2-hbc-iam-auth.json .
aws s3 cp s3://msk-zwy2.us-gov-west-1.configs/connector/mm2-cpc-iam-auth.json .
aws s3 cp s3://msk-zwy2.us-gov-west-1.configs/connector/mm2-msc-iam-auth.json .

aws ecs execute-command  \
    --region us-gov-west-1 \
    --cluster msk-zwy2_us-gov-west-1_ecs_default \
    --task c40094f3b3a048d987d0f3241fe767c5 \
    --container kafka-connect \
    --command "/bin/sh" \
    --interactive
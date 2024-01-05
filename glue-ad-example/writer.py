import datetime
import json
import os
import random
import uuid

import boto3
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext

s3 = boto3.client("s3")
names = [
    "Moiraine",
    "Daemondred",
    "Lan",
    "Lanfear",
    "Rand",
    "Mazrim",
    "Perrin",
    "Mat",
    "Nyneave",
    "Egwene",
    "Semerage",
]
colors = ["Red", "Blue", "Green", "Brown", "Yellow", "Gray", "Black"]
bucket = os.environ["BUCKET_NAME"]
logger = Logger()


@logger.inject_lambda_context(log_event=True)
def handler(event: dict, context: LambdaContext):
    of = ""
    for _ in range(0, 10_000):
        event = {}
        event["timestamp"] = str(datetime.datetime.now())
        event["name"] = random.choice(names)
        event["color"] = random.choice(colors)
        event["magnitude"] = random.uniform(0, 100)
        event["scale"] = random.gauss(0.5, 0.2)
        event["rate"] = random.expovariate(0.2)
        of += json.dumps(event)
        of += "\n"
    key = f'wot/{datetime.datetime.now().strftime("%Y/%m/%d/%H")}/{str(uuid.uuid4())[0:6]}.jsonl'
    logger.info({"key": key, "size": len(of) / 1024, "sample": event})
    s3.put_object(Bucket=bucket, Key=key, Body=of)

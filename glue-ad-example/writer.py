import datetime
import json
import os
import random
import uuid
import math

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
    x = datetime.datetime.now().hour / 24
    scale = abs(math.exp(-(4 * x - 2) ** 2))
    shuffle = random.randint(1, 100)
    count = int(10_000 * scale) + shuffle
    for _ in range(0, count):
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

    of = ""
    x = int(f"{datetime.datetime.now().hour}{datetime.datetime.now().minute:02}") / 2359
    scale = abs(math.exp(-(4 * x - 2) ** 2))
    shuffle = int(datetime.datetime.now().timestamp()  - 1704988707)
    count = int(10_000 * scale) + shuffle
    order = datetime.datetime.now().strftime("%Y%m%d%H%M")
    oids = set()
    for oid in range(0, count):
        event = {}
        event["timestamp"] = str(datetime.datetime.now())
        event["id"] = str(uuid.uuid4())
        event["product_id"] = random.randint(0, 50)
        event["count"] = abs(random.gauss(1, 0.2) * 500)
        event["order_id"] = f"{oid % 50}_{order}"
        oids.add(event["order_id"])
        of += json.dumps(event)
        of += "\n"
    key = f'sales/{datetime.datetime.now().strftime("%Y/%m/%d/%H")}/{str(uuid.uuid4())[0:6]}.jsonl'
    logger.info({"key": key, "size": len(of) / 1024, "sample": event})
    s3.put_object(Bucket=bucket, Key=key, Body=of)

    of = ""
    for o in oids:
        event = {}
        event["timestamp"] = str(datetime.datetime.now())
        event["id"] = o
        event["customer_id"] = random.randint(0, 500)
        of += json.dumps(event)
        of += "\n"
    key = f'orders/{datetime.datetime.now().strftime("%Y/%m/%d/%H")}/{str(uuid.uuid4())[0:6]}.jsonl'
    logger.info({"key": key, "size": len(of) / 1024, "sample": event})
    s3.put_object(Bucket=bucket, Key=key, Body=of)

# c = ["Paper", "Cardstock"]
# s = ["A24", "A11", "A15", "A14"]
# q = ["Fine", "Medium", "Coarse"]
# t = ["Thick", "Thin", "Clean"]
# import itertools
# f = list(itertools.product(c, s, q, t))

# def load():
#     of = ""
#     for i, o in enumerate(f):
#         event = {}
#         event["id"] = i
#         event["name"] = ", ".join(o)
#         event["type"] = o[0]
#         event["size"] = o[1]
#         event["grain"] = o[2]
#         event["quality"] = o[3]
#         of += json.dumps(event)
#         of += "\n"
#     key = f'products/{datetime.datetime.now().strftime("%Y/%m/%d/%H")}/{str(uuid.uuid4())[0:6]}.jsonl'
#     logger.info({"key": key, "size": len(of) / 1024, "sample": event})
#     s3.put_object(Bucket=bucket, Key=key, Body=of)

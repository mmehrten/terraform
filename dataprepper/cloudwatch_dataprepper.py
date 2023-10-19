import base64
import gzip
import json
import os
import time

import requests
from requests.exceptions import ConnectionError

DATAPREPPER_ENDPOINT = os.environ["DATAPREPPER_ENDPOINT"]


def process_records(events):
    for event in events:
        data = unpack(event["kinesis"]["data"])
        # CONTROL_MESSAGE are sent by CWL to check if the subscription is reachable.
        # They do not contain actual data.
        if data["messageType"] == "CONTROL_MESSAGE":
            yield {"result": None, "source": data}
        elif data["messageType"] == "DATA_MESSAGE":
            common_data = {
                "owner": data["owner"],
                "logGroup": data["logGroup"],
                "logStream": data["logStream"],
            }
            for e in data["logEvents"]:
                e.update(**common_data)
                del e["id"]
                yield {"data": e, "result": True, "source": data}
        else:
            yield {"result": False, "source": data}


def unpack(encoded_data):
    return json.loads(gzip.decompress(base64.b64decode(encoded_data)))


def lambda_handler(event, _):
    failed = []
    ok = []
    for i in process_records(event["Records"]):
        if not i["result"]:
            failed.append(i)
        else:
            ok.append(i)
    if failed:
        print(f"ERROR: Failed to ingest records: {failed}")
    if ok:
        tried = 0
        while tried < 3:
            try:
                tried += 1
                requests.post(
                    DATAPREPPER_ENDPOINT, data=json.dumps([i["data"] for i in ok])
                )
                break
            except ConnectionError:
                time.sleep(2)
    return True

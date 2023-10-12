import base64
import gzip
import json

import boto3


def processRecords(records):
    for r in records:
        data = loadJsonGzipBase64(r["data"])
        recId = r["recordId"]
        # CONTROL_MESSAGE are sent by CWL to check if the subscription is reachable.
        # They do not contain actual data.
        if data["messageType"] == "CONTROL_MESSAGE":
            yield {"result": "Dropped", "recordId": recId}
        elif data["messageType"] == "DATA_MESSAGE":
            for e in data["logEvents"]:
                try:
                    message = e["message"]
                    e["message"] = json.loads(message)
                    e["raw"] = message
                except Exception as e:
                    pass
            encodedData = base64.b64encode(json.dumps(data).encode("utf-8")).decode("utf-8")
            yield {"data": encodedData, "result": "Ok", "recordId": recId}
        else:
            yield {"result": "ProcessingFailed", "recordId": recId}


def splitCWLRecord(cwlRecord):
    """
    Splits one CWL record into two, each containing half the log events.
    Serializes and compreses the data before returning. That data can then be
    re-ingested into the stream, and it'll appear as though they came from CWL
    directly.
    """
    logEvents = cwlRecord["logEvents"]
    mid = len(logEvents) // 2
    rec1 = {k: v for k, v in cwlRecord.items()}
    rec1["logEvents"] = logEvents[:mid]
    rec2 = {k: v for k, v in cwlRecord.items()}
    rec2["logEvents"] = logEvents[mid:]
    return [gzip.compress(json.dumps(r).encode("utf-8")) for r in [rec1, rec2]]


def putRecordsToFirehoseStream(streamName, records, client, attemptsMade, maxAttempts):
    failedRecords = []
    codes = []
    errMsg = ""
    # if put_record_batch throws for whatever reason, response['xx'] will error out, adding a check for a valid
    # response will prevent this
    response = None
    try:
        response = client.put_record_batch(
            DeliveryStreamName=streamName, Records=records
        )
    except Exception as e:
        failedRecords = records
        errMsg = str(e)

    # if there are no failedRecords (put_record_batch succeeded), iterate over the response to gather results
    if not failedRecords and response and response["FailedPutCount"] > 0:
        for idx, res in enumerate(response["RequestResponses"]):
            # (if the result does not have a key 'ErrorCode' OR if it does and is empty) => we do not need to re-ingest
            if not res.get("ErrorCode"):
                continue

            codes.append(res["ErrorCode"])
            failedRecords.append(records[idx])

        errMsg = "Individual error codes: " + ",".join(codes)

    if failedRecords:
        if attemptsMade + 1 < maxAttempts:
            print(
                "Some records failed while calling PutRecordBatch to Firehose stream, retrying. %s"
                % (errMsg)
            )
            putRecordsToFirehoseStream(
                streamName, failedRecords, client, attemptsMade + 1, maxAttempts
            )
        else:
            raise RuntimeError(
                "Could not put records after %s attempts. %s"
                % (str(maxAttempts), errMsg)
            )


def putRecordsToKinesisStream(streamName, records, client, attemptsMade, maxAttempts):
    failedRecords = []
    codes = []
    errMsg = ""
    # if put_records throws for whatever reason, response['xx'] will error out, adding a check for a valid
    # response will prevent this
    response = None
    try:
        response = client.put_records(StreamName=streamName, Records=records)
    except Exception as e:
        failedRecords = records
        errMsg = str(e)

    # if there are no failedRecords (put_record_batch succeeded), iterate over the response to gather results
    if not failedRecords and response and response["FailedRecordCount"] > 0:
        for idx, res in enumerate(response["Records"]):
            # (if the result does not have a key 'ErrorCode' OR if it does and is empty) => we do not need to re-ingest
            if not res.get("ErrorCode"):
                continue

            codes.append(res["ErrorCode"])
            failedRecords.append(records[idx])

        errMsg = "Individual error codes: " + ",".join(codes)

    if failedRecords:
        if attemptsMade + 1 < maxAttempts:
            print(
                "Some records failed while calling PutRecords to Kinesis stream, retrying. %s"
                % (errMsg)
            )
            putRecordsToKinesisStream(
                streamName, failedRecords, client, attemptsMade + 1, maxAttempts
            )
        else:
            raise RuntimeError(
                "Could not put records after %s attempts. %s"
                % (str(maxAttempts), errMsg)
            )


def createReingestionRecord(isSas, originalRecord, data=None):
    if data is None:
        data = base64.b64decode(originalRecord["data"])
    r = {"Data": data}
    if isSas:
        r["PartitionKey"] = originalRecord["kinesisRecordMetadata"]["partitionKey"]
    return r


def loadJsonGzipBase64(base64Data):
    return json.loads(gzip.decompress(base64.b64decode(base64Data)))


def lambda_handler(event, context):
    isSas = "sourceKinesisStreamArn" in event
    streamARN = event["sourceKinesisStreamArn"] if isSas else event["deliveryStreamArn"]
    region = streamARN.split(":")[3]
    streamName = streamARN.split("/")[1]
    records = list(processRecords(event["records"]))
    projectedSize = 0
    recordListsToReingest = []

    for idx, rec in enumerate(records):
        originalRecord = event["records"][idx]

        if rec["result"] != "Ok":
            continue

        # If a single record is too large after processing, split the original CWL data into two, each containing half
        # the log events, and re-ingest both of them (note that it is the original data that is re-ingested, not the
        # processed data). If it's not possible to split because there is only one log event, then mark the record as
        # ProcessingFailed, which sends it to error output.
        if len(rec["data"]) > 6000000:
            cwlRecord = loadJsonGzipBase64(originalRecord["data"])
            if len(cwlRecord["logEvents"]) > 1:
                rec["result"] = "Dropped"
                recordListsToReingest.append(
                    [
                        createReingestionRecord(isSas, originalRecord, data)
                        for data in splitCWLRecord(cwlRecord)
                    ]
                )
            else:
                rec["result"] = "ProcessingFailed"
                print(
                    (
                        "Record %s contains only one log event but is still too large after processing (%d bytes), "
                        + "marking it as %s"
                    )
                    % (rec["recordId"], len(rec["data"]), rec["result"])
                )
            del rec["data"]
        else:
            projectedSize += len(rec["data"]) + len(rec["recordId"])
            # 6000000 instead of 6291456 to leave ample headroom for the stuff we didn't account for
            if projectedSize > 6000000:
                recordListsToReingest.append(
                    [createReingestionRecord(isSas, originalRecord)]
                )
                del rec["data"]
                rec["result"] = "Dropped"

    # call putRecordBatch/putRecords for each group of up to 500 records to be re-ingested
    if recordListsToReingest:
        recordsReingestedSoFar = 0
        client = boto3.client("kinesis" if isSas else "firehose", region_name=region)
        maxBatchSize = 500
        flattenedList = [r for sublist in recordListsToReingest for r in sublist]
        for i in range(0, len(flattenedList), maxBatchSize):
            recordBatch = flattenedList[i : i + maxBatchSize]
            # last argument is maxAttempts
            args = [streamName, recordBatch, client, 0, 20]
            if isSas:
                putRecordsToKinesisStream(*args)
            else:
                putRecordsToFirehoseStream(*args)
            recordsReingestedSoFar += len(recordBatch)
            print("Reingested %d/%d" % (recordsReingestedSoFar, len(flattenedList)))

    print(
        "%d input records, %d returned as Ok or ProcessingFailed, %d split and re-ingested, %d re-ingested as-is"
        % (
            len(event["records"]),
            len([r for r in records if r["result"] != "Dropped"]),
            len([l for l in recordListsToReingest if len(l) > 1]),
            len([l for l in recordListsToReingest if len(l) == 1]),
        )
    )

    return {"records": records}

import re
import boto3
from langchain.text_splitter import NLTKTextSplitter
from opensearchpy import OpenSearch, helpers
import time
import nltk
nltk.data.path += [
    # Point nltk to tokenizers that are uploaded in Lambda layer
    "/opt/python/"
]
text_splitter = NLTKTextSplitter()

METADATA_PATTERN = re.compile(r'.+id="(?P<id>[^"]+)".+title="(?P<title>[^"]+)".+')
s3 = boto3.client("s3")
INDEX = "demo-nlp-index"

def handle_record(object_data: str, object_uri: str):
    example = {}
    text = []
    print("Handling document, size: ", len(object_data))
    for row in object_data.split("\n"):
        if row.startswith("<doc id"):
            metadata_match = METADATA_PATTERN.match(row)
            example["id"] = metadata_match.group("id") if metadata_match else ""
            example["title"] = metadata_match.group("title") if metadata_match else ""
        elif row.startswith("</doc>"):
            pass
        elif row.startswith("ENDOFARTICLE"):
            yield {
                "_index": INDEX,
                "_id": example["id"],
                "title": example["title"],
                "uri": object_uri,
                "text": "\n".join(text).strip(),
            }
            example = {}
            text = []
        else:
            text.append(row)
    if text and example:
        yield {
                "_index": INDEX,
                "_id": f'{example["id"]}_eoa',
                "title": example["title"],
                "uri": object_uri,
                "text": "\n".join(text).strip(),
            }

def handle_sqs_event(client: OpenSearch, event: dict, context):
    docs_to_push = []
    # document_count = sentence_count = 0
    for record in event["Records"]:
        data = s3.get_object(Bucket=record["s3"]["bucket"]["name"], Key=record["s3"]["object"]["key"])
        content = data["Body"].read().decode("latin-1")
        url = f's3://{record["s3"]["bucket"]["name"]}/{record["s3"]["object"]["key"]}'
        for opensearch_record in handle_record(content, url):
            # document_count += 1
            # sentence_count = 0
            data = text_splitter.split_text(opensearch_record["text"])
            for idx, sentence in enumerate(data):
                    sentence_record = opensearch_record.copy()
                    sentence_record["_id"] = f"{sentence_record['_id']}_{idx}"
                    sentence_record["text"] = sentence.strip()
                    sentence_record["upload_timestamp"] = record["eventTime"]
                    sentence_record["processed_timestamp"] = int(time.time() * 1000)
                    docs_to_push.append(sentence_record)
                    # sentence_count += 1
            # print(f"Identified {sentence_count} total sentences in this document")
    # print(f"Identified {document_count} total documents in this record")
    succeeded = []
    failed = []
    print("Starting OpenSearch upload")
    for success, item in helpers.streaming_bulk(
        client,
        actions=docs_to_push,
        chunk_size=100,
        raise_on_error=False,
        raise_on_exception=False,
        max_chunk_bytes=20 * 1024 * 1024,
        request_timeout=60,
    ):
        if success:
            succeeded.append(item)
        else:
            print("FAIL", item["index"]["error"])
            failed.append(item)

    print(f"Uploaded {len(succeeded)}/{len(docs_to_push)} documents")
    if len(failed) > 0:
        print(f"There were {len(failed)} errors:")
        for item in failed:
            print(item["index"]["error"])

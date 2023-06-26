import json

import boto3
import yaml

s3 = boto3.resource('s3')

def process_record(record):
    bucket = record['s3']['bucket']['name']
    key = record['s3']['object']['key']
    key_prefix = key.rsplit(".", 1)[0]

    yaml_data = s3.Object(bucket_name=bucket, key=key).get()
    doc = yaml.load(yaml_data['Body'], Loader=yaml.CSafeLoader)
    
    json_obj = s3.Object(bucket_name=bucket, key=f"{key_prefix}.json")
    json_obj.put(Body=json.dumps(doc).encode())


def handler(event, context):
    for record in event['Records']:
        process_record(record)

    print(f"Processed {len(event['Records'])} records")

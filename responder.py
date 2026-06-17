import boto3
import json
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

client = boto3.client('lambda')
FUNCTION = os.environ['PROCESSOR_FUNCTION_NAME']

def throttle():
    client.put_function_concurrency(FunctionName=FUNCTION, ReservedConcurrentExecutions=2)
    logger.info("throttled %s", FUNCTION)

def restore():
    client.delete_function_concurrency(FunctionName=FUNCTION)
    logger.info("restored %s", FUNCTION)

def lambda_handler(event, context):
    alerts = json.loads(event.get('body', '{}')).get('alerts', [])

    for alert in alerts:
        if alert['labels'].get('alertname') != 'HighErrorRate':
            continue
        if alert['status'] == 'firing':
            throttle()
        elif alert['status'] == 'resolved':
            restore()

    return {'statusCode': 200, 'body': 'ok'}

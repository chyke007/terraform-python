import json

def lambda_handler(event, context):
    response = { "data": "Fake api endpoint" }
    return {
        "statusCode": 200,
        "body": json.dumps(response)
    }

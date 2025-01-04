import json

def lambda_handler(event, context):
    response = { "data": "Test api endpoint" }
    return {
        "statusCode": 200,
        "body": json.dumps(response)
    }

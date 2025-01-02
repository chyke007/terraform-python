import json

import requests


def lambda_handler(event, context):

    api_url = "https://hello.io/users/"
    response = requests.get(api_url)
    if response.status_code == 200:
        data = response.json()
        res = data
    else:
        res = "Empty"

    return {
        "statusCode": 200,
        "body": json.dump({
            "data": res,
            "message": "Response is attached"
        })
    }

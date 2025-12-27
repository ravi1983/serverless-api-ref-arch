import json
from serverless.cart_actions.process_cart_action import process_cart_action

def lambda_handler(event):
    result = process_cart_action(
        event.get('eventType'),
        event['queryStringParameters']['userId'],
        event.get('body', '{}')
    )
    return {'statusCode': 200, 'body': json.dumps(result, default=str)}
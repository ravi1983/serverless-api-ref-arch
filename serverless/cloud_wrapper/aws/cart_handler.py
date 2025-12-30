import json
from serverless.cart_actions.process_cart_action import process_cart_action

def lambda_handler(event, context):
    # Determine the action based on the HTTP method
    method_map = {
        "GET": "getCart",
        "POST": "add",
        "DELETE": "removeItem"
    }
    http_method = event['requestContext']['http']['method']
    event_type = method_map.get(http_method)
    print(f'Event type is {event_type}')

    result = process_cart_action(
        event_type,
        event['queryStringParameters']['userId'],
        event.get('body', '{}')
    )
    return {'statusCode': 200, 'body': json.dumps(result, default=str)}
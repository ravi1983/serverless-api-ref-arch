import json
from serverless.cart_actions.cart_actions import add_item_to_cart, get_cart, remove_from_cart

def lambda_handler(event):
    eventType = event.get('eventType')
    user_id = event['queryStringParameters']['userId']
    
    if eventType == 'add':
        body = json.loads(event['body'])
        result = add_item_to_cart(user_id, body['itemId'])
    elif eventType == 'removeItem':
        body = json.loads(event['body'])
        result = remove_from_cart(user_id, body['itemId'])
    else:
        result = get_cart(user_id)
        
    return {
        'statusCode': 200,
        'body': json.dumps(result, default=str)
    }
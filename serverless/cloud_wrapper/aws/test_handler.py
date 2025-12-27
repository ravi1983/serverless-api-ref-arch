import json
from serverless.cloud_wrapper.aws.cart_handler import lambda_handler

def test_add_to_cart_full_integration():
    # 1. Prepare a real-looking event
    event = {
        'eventType': 'add',
        'queryStringParameters': {'userId': 'user_abc'},
        'body': json.dumps({'itemId': 'item123'}) # This item was inserted into Postgres in conftest.py
    }

    # 2. Execute the actual handler
    response = lambda_handler(event)

    # 3. Assertions
    assert response['statusCode'] == 200
    body = json.loads(response['body'])
    assert body['success'] is True
    assert body['item']['description'] == 'Real Test Item'
    assert float(body['item']['price']) == 19.99
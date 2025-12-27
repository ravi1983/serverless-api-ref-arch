import json, os, pytest
from unittest.mock import patch
from serverless.cart_handler import lambda_handler
from unittest.mock import patch, MagicMock

@patch('serverless.cart_handler.add_item_to_cart')
def test_handler_add_item(mock_add):
    # Setup mock return value
    mock_add.return_value = {"success": True, "item": "test_item"}
    
    # Simulate API Gateway / Lambda Event
    event = {
        'eventType': 'add',
        'queryStringParameters': {'userId': 'user123'},
        'body': json.dumps({'itemId': 'prod_001'})
    }

    response = lambda_handler(event)

    # Assertions
    assert response['statusCode'] == 200
    assert "test_item" in response['body']
    mock_add.assert_called_once_with('user123', 'prod_001')

@patch('serverless.cart_handler.remove_from_cart')
def test_handler_remove_item(mock_remove):
    mock_remove.return_value = {"success": True}
    
    event = {
        'eventType': 'removeItem',
        'queryStringParameters': {'userId': 'user123'},
        'body': json.dumps({'itemId': 'prod_001'})
    }

    response = lambda_handler(event)

    assert response['statusCode'] == 200
    mock_remove.assert_called_once_with('user123', 'prod_001')

@patch('serverless.cart_handler.get_cart')
def test_handler_get_cart_default(mock_get):
    mock_get.return_value = {"items": []}
    
    # Testing the 'else' case (no eventType or different eventType)
    event = {
        'eventType': 'view',
        'queryStringParameters': {'userId': 'user123'}
    }

    response = lambda_handler(event)

    assert response['statusCode'] == 200
    mock_get.assert_called_once_with('user123')
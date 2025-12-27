import json
import pytest
from unittest.mock import patch
from serverless.cart_actions.process_cart_action import process_cart_action

# Note: We patch the functions where they are imported into core_logic
BASE_PATH = 'serverless.cart_actions.process_cart_action'

@patch(f'{BASE_PATH}.add_item_to_cart')
def test_process_add(mock_add):
    mock_add.return_value = {"success": True}
    body_str = json.dumps({'itemId': 'item_123'})
    
    result = process_cart_action('add', 'user_1', body_str)
    
    assert result["success"] is True
    mock_add.assert_called_once_with('user_1', 'item_123')

@patch(f'{BASE_PATH}.remove_from_cart')
def test_process_remove(mock_remove):
    mock_remove.return_value = {"success": True}
    body_str = json.dumps({'itemId': 'item_123'})
    
    result = process_cart_action('removeItem', 'user_1', body_str)
    
    assert result["success"] is True
    mock_remove.assert_called_once_with('user_1', 'item_123')

@patch(f'{BASE_PATH}.get_cart')
def test_process_get_default(mock_get):
    mock_get.return_value = {"items": []}
    
    # Passing 'view' or any other string should trigger the else (get_cart)
    result = process_cart_action('view', 'user_1', None)
    
    assert "items" in result
    mock_get.assert_called_once_with('user_1')
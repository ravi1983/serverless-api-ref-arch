import os
import boto3
import pytest
import time
from moto import mock_aws
from unittest.mock import patch, MagicMock

# Import your functions
from serverless.cart_actions.cart_actions import add_item_to_cart, get_cart, remove_from_cart

@pytest.fixture(scope="session", autouse=True)
def setup_env():
    os.environ["CART_TABLE_NAME"] = "TestTable"
    os.environ["DATABASE_URL"] = "postgres://user:pass@localhost:5432/db"
    os.environ["AWS_ACCESS_KEY_ID"] = "testing"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
    os.environ["AWS_DEFAULT_REGION"] = "us-east-1"

@pytest.fixture
def setup_dynamo():
    """Fixture to initialize a fresh mock table with Composite Key."""
    with mock_aws():
        db = boto3.resource('dynamodb', region_name='us-east-1')
        table = db.create_table(
            TableName='TestTable',
            KeySchema=[
                {'AttributeName': 'userId', 'KeyType': 'HASH'},
                {'AttributeName': 'itemId', 'KeyType': 'RANGE'} # Sort Key
            ],
            AttributeDefinitions=[
                {'AttributeName': 'userId', 'AttributeType': 'S'},
                {'AttributeName': 'itemId', 'AttributeType': 'S'}
            ],
            ProvisionedThroughput={'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1}
        )
        yield table

@mock_aws
def test_add_item_to_cart(setup_dynamo):
    # Mock RDS Connection and Cursor
    with patch('serverless.db_layer.db.psycopg2.connect') as mock_connect:
        mock_conn = MagicMock()
        mock_cur = MagicMock()

        # Simulate RDS returning a product
        mock_cur.fetchone.return_value = {
            'id': 123,
            'description': 'Test Product',
            'price': 10.00
        }
        mock_conn.cursor.return_value.__enter__.return_value = mock_cur
        mock_connect.return_value = mock_conn

        # Call function
        result = add_item_to_cart('user1', 123)

        # Assertions based on your ACTUAL return: {"success": True, "cart": get_cart(user_id)}
        assert result['success'] is True
        assert result['cart']['userId'] == 'user1'
        assert result['cart']['itemCount'] == 1
        assert result['cart']['items'][0]['itemId'] == '123' # Check string conversion

def test_get_cart_multiple_items(setup_dynamo):
    table = setup_dynamo
    # Seed mock table
    table.put_item(Item={'userId': 'user1', 'itemId': 'itemA', 'description': 'A', 'price': '10'})
    table.put_item(Item={'userId': 'user1', 'itemId': 'itemB', 'description': 'B', 'price': '20'})
    table.put_item(Item={'userId': 'user2', 'itemId': 'itemC', 'description': 'C', 'price': '30'})

    result = get_cart('user1')

    assert result['userId'] == 'user1'
    assert len(result['items']) == 2
    assert result['itemCount'] == 2

def test_remove_from_cart(setup_dynamo):
    table = setup_dynamo
    # Seed an item
    table.put_item(Item={'userId': 'user1', 'itemId': 'item123', 'price': '10'})

    # Your function returns: {"success": True, "cart": get_cart(user_id)}
    result = remove_from_cart('user1', 'item123')

    assert result['success'] is True
    assert result['cart']['itemCount'] == 0

    # Verify deletion from DynamoDB
    response = table.get_item(Key={'userId': 'user1', 'itemId': 'item123'})
    assert 'Item' not in response
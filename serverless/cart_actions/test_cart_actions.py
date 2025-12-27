import os
import boto3
import pytest
from moto import mock_aws
from unittest.mock import patch, MagicMock

from serverless.cart_actions.cart_actions import add_item_to_cart, get_cart, remove_from_cart

# Set dummy env vars for testing
os.environ['CART_TABLE_NAME'] = 'TestTable'
os.environ['DATABASE_URL'] = 'postgres://user:pass@host:5432/db'

@pytest.fixture(scope="session", autouse=True)
def setup_env():
    os.environ["CART_TABLE_NAME"] = "TestTable"
    os.environ["DATABASE_URL"] = "postgres://user:pass@localhost:5432/db"
    os.environ["AWS_ACCESS_KEY_ID"] = "testing"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
    os.environ["AWS_SECURITY_TOKEN"] = "testing"
    os.environ["AWS_SESSION_TOKEN"] = "testing"
    os.environ["AWS_DEFAULT_REGION"] = "us-east-1"

@pytest.fixture
def setup_dynamo():
    """Fixture to initialize a fresh mock table for each test."""
    with mock_aws():
        boto3.setup_default_session()
        db = boto3.resource('dynamodb', region_name='us-east-1')
        table = db.create_table(
            TableName='TestTable',
            KeySchema=[
                {'AttributeName': 'userId', 'KeyType': 'HASH'}, 
                {'AttributeName': 'itemId', 'KeyType': 'RANGE'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'userId', 'AttributeType': 'S'}, 
                {'AttributeName': 'itemId', 'AttributeType': 'S'}
            ],
            ProvisionedThroughput={'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1}
        )
        yield table

@mock_aws
def test_add_item_to_cart():
    # 1. Setup Mock DynamoDB
    db = boto3.resource('dynamodb', region_name='us-east-1')
    db.create_table(
        TableName='TestTable',
        KeySchema=[{'AttributeName': 'userId', 'KeyType': 'HASH'}, 
                   {'AttributeName': 'itemId', 'KeyType': 'RANGE'}],
        AttributeDefinitions=[{'AttributeName': 'userId', 'AttributeType': 'S'}, 
                             {'AttributeName': 'itemId', 'AttributeType': 'S'}],
        ProvisionedThroughput={'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1}
    )

    # 2. Mock RDS Connection
    with patch('serverless.db_layer.db.psycopg2.connect') as mock_connect:
        mock_conn = MagicMock()
        mock_cur = MagicMock()
        mock_cur.fetchone.return_value = {
            'id': 'item123', 'description': 'Test', 'price': 10.00
        }
        mock_conn.cursor.return_value.__enter__.return_value = mock_cur
        mock_connect.return_value = mock_conn

        result = add_item_to_cart('user1', 'item123')

        assert result['success'] is True
        assert result['addedItem']['userId'] == 'user1'

def test_get_cart_multiple_items(setup_dynamo):
    table = setup_dynamo
    # Manually seed the mock table with two items for the same user
    table.put_item(Item={'userId': 'user1', 'itemId': 'itemA', 'price': 10, 'ttl': 0})
    table.put_item(Item={'userId': 'user1', 'itemId': 'itemB', 'price': 20, 'ttl': 0})
    # Add an item for a different user to ensure filtering works
    table.put_item(Item={'userId': 'user2', 'itemId': 'itemC', 'price': 30, 'ttl': 0})

    result = get_cart('user1')

    assert result['userId'] == 'user1'
    assert len(result['items']) == 2
    assert any(i['itemId'] == 'itemA' for i in result['items'])
    assert any(i['itemId'] == 'itemB' for i in result['items'])

def test_remove_from_cart(setup_dynamo):
    table = setup_dynamo
    # Seed an item to delete
    table.put_item(Item={'userId': 'user1', 'itemId': 'item123', 'price': 10, 'ttl': 0})

    result = remove_from_cart('user1', 'item123')

    assert result['success'] is True
    assert result['removedItemId'] == 'item123'

    # Verify it's actually gone from the mock DB
    response = table.get_item(Key={'userId': 'user1', 'itemId': 'item123'})
    assert 'Item' not in response

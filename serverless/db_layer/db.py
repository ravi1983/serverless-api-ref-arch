import os
import psycopg2
import boto3

def get_cart_table():
    CART_TABLE = os.environ.get('CART_TABLE_NAME', 'UserCarts')

    endpoint = os.environ.get('DYNAMODB_ENDPOINT') # For integration testing
    print(f'Endpoint got from env is {endpoint}')
    dynamodb = boto3.resource('dynamodb')
    return dynamodb.Table(CART_TABLE)

def get_psql_connection():
    """Returns a connection to the RDS Postgres instance."""
    conn = psycopg2.connect(
        os.environ['DATABASE_URL'],
        sslmode='require'
    )
    return conn

import os
import psycopg2
import boto3
import json

def get_cart_table():
    cart_table = os.environ.get('CART_TABLE_NAME', 'UserCarts')

    endpoint = os.environ.get('DYNAMODB_ENDPOINT') # For integration testing
    print(f'Endpoint got from env is {endpoint}')
    dynamodb = boto3.resource('dynamodb')
    return dynamodb.Table(cart_table)

secret_arn = os.getenv('DB_SECRET_ARN')
if secret_arn:
    secretsmanager = boto3.client('secretsmanager')
    db_creds = secretsmanager.get_secret_value(SecretId=secret_arn)
else:
    db_creds = {'SecretString': '{"username": "postgres", "password": ""}'}

def get_psql_connection():
    """Returns a connection to the RDS Postgres instance."""
    print(f'DB URL is {os.environ["DATABASE_URL"]}')

    creds = json.loads(db_creds['SecretString'])
    conn = psycopg2.connect(
        host=os.environ['DATABASE_URL'],
        user=creds['username'],
        password=creds['password'],
        database='item_catalog_db',
        sslmode='require'
    )
    return conn

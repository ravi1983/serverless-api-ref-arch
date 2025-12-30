import os
import psycopg2
import boto3
import json

def get_cart_table():
    CART_TABLE = os.environ.get('CART_TABLE_NAME', 'UserCarts')

    endpoint = os.environ.get('DYNAMODB_ENDPOINT') # For integration testing
    print(f'Endpoint got from env is {endpoint}')
    dynamodb = boto3.resource('dynamodb')
    return dynamodb.Table(CART_TABLE)

secret_arn = os.environ['DB_SECRET_ARN']
if secret_arn:
    secretsmanager = boto3.client('secretsmanager')
    db_creds = secretsmanager.get_secret_value(SecretId=secret_arn)
    creds = json.loads(db_creds['SecretString'])
    os.environ['DATABASE_FULL_URL'] = f'postgres://{creds['username']}:\
            {creds['password']}@{os.environ['DATABASE_URL']}/item_catalog_db'
    print(f'********************Database URL is {os.environ["DATABASE_FULL_URL"]}')

def get_psql_connection():
    """Returns a connection to the RDS Postgres instance."""
    print(f'DB URL is {os.environ["DATABASE_URL"]}')
    conn = psycopg2.connect(
        host=os.environ['DATABASE_FULL_URL'],
        sslmode='require'
    )
    return conn

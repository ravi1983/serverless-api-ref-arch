import os
import psycopg2
import boto3
import json
import logging

def get_cart_table():
    runtime = os.environ.get('CLOUD_RUNTIME', 'AWS').upper()
    cart_table = os.environ.get('CART_TABLE_NAME', 'UserCarts')

    if runtime == 'AZURE':
        from azure.cosmos import CosmosClient
        # Cosmos DB requires Endpoint and Key (or a Connection String)
        endpoint = os.environ.get('COSMOS_ENDPOINT')
        key = os.environ.get('COSMOS_KEY')
        database_name = os.environ.get('COSMOS_DATABASE', 'ShoppingCartDB')

        client = CosmosClient(endpoint, key)
        database = client.get_database_client(database_name)
        logging.info(f'Database client got from Cosmos is {database}')

        return database.get_container_client(cart_table)
    else:
        endpoint = os.environ.get('DYNAMODB_ENDPOINT')
        logging.info(f'Endpoint got from env is {endpoint}')

        # Use the endpoint_url parameter if an override exists (common in local/test envs)
        dynamodb = boto3.resource('dynamodb', endpoint_url = endpoint)
        return dynamodb.Table(cart_table)

secret_arn = os.getenv('DB_SECRET_ARN')
if secret_arn:
    secretsmanager = boto3.client('secretsmanager')
    db_creds = secretsmanager.get_secret_value(SecretId=secret_arn)
else:
    db_creds = {'SecretString': '{"username": "postgres", "password": ""}'}

def get_psql_connection():
    """Returns a connection to the RDS Postgres instance."""
    logging.info(f'DB URL is {os.environ["DATABASE_URL"]}')

    creds = json.loads(db_creds['SecretString'])
    conn = psycopg2.connect(
        host=os.environ['DATABASE_URL'],
        user=creds['username'],
        password=creds['password'],
        database='item_catalog_db',
        sslmode='require'
    )
    logging.info('Connected to Postgres')

    return conn

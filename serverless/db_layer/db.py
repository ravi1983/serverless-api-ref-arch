import os
import json
import logging

runtime = os.environ.get('CLOUD_RUNTIME', 'AWS').upper()

def get_cart_table():
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
    elif runtime == 'GCP':
        from google.cloud import firestore

        db = firestore.Client()
        logging.info(f'Firestore client initialized for collection: {cart_table}')
        return db.collection(cart_table)
    else:
        import boto3

        endpoint = os.environ.get('DYNAMODB_ENDPOINT')
        logging.info(f'Endpoint got from env is {endpoint}')

        # Use the endpoint_url parameter if an override exists (common in local/test envs)
        dynamodb = boto3.resource('dynamodb', endpoint_url = endpoint)
        return dynamodb.Table(cart_table)

secret_arn = os.getenv('DB_SECRET_ARN')
if secret_arn:
    import boto3

    secretsmanager = boto3.client('secretsmanager')
    db_creds = secretsmanager.get_secret_value(SecretId=secret_arn)
else:
    db_creds = {'SecretString': '{"username": "postgres", "password": ""}'}


def _postgres_connect(creds):
    import psycopg2
    try:
        conn = psycopg2.connect(
            host=os.environ['DATABASE_URL'],
            user=creds['username'],
            password=creds['password'],
            database='item_catalog_db',
            sslmode='require'
        )
        logging.info('Connected to Postgres')
    except Exception as e:
        logging.error(f'Error connecting to Postgres: {e}')
        raise e

    return conn

def _cloud_sql_connect(creds):
    from google.cloud.sql.connector import Connector, IPTypes
    connector = Connector()

    try:
        conn = connector.connect(
            os.environ['DATABASE_URL'],
            "psycopg2",
            user=creds['username'],
            password=creds['password'],
            database='item_catalog_db',
            ip_type=IPTypes.PRIVATE
        )
        logging.info('Connected to Postgres')
    except Exception as e:
        logging.error(f'Error connecting to Postgres: {e}')
        raise e

    return conn

def get_psql_connection():
    """Returns a connection to the RDS Postgres instance."""
    logging.info(f'DB URL is {os.environ["DATABASE_URL"]}')

    if runtime == 'AZURE' or runtime == 'GCP':
        creds = {"username": os.environ['DB_USER'], "password": os.environ['DB_PASSWORD']}
    else:
        creds = json.loads(db_creds['SecretString'])

    if runtime == 'GCP':
        return _cloud_sql_connect(creds)
    else:
        return _postgres_connect(creds)

import os
import pytest
from testcontainers.postgres import PostgresContainer
from testcontainers.localstack import LocalStackContainer

@pytest.fixture(scope="session", autouse=True)
def setup_infrastructure():

    print('***********************************************************')
    # 1. Start Postgres
    postgres = PostgresContainer("postgres:16-alpine")
    postgres.start()

    # 2. Start LocalStack (for DynamoDB)
    localstack = LocalStackContainer(image="localstack/localstack:latest")
    localstack.start()

    # 3. Set Environment Variables so your code "sees" the containers
    os.environ["DATABASE_URL"] = postgres.get_connection_url()
    os.environ["CART_TABLE_NAME"] = "IntegrationTestCart"
    # DynamoDB needs a special endpoint_url to talk to the container
    os.environ["DYNAMODB_ENDPOINT"] = localstack.get_url()

    # 4. Initialize the DynamoDB Table
    ddb = localstack.get_client("dynamodb")
    ddb.create_table(
        TableName="IntegrationTestCart",
        KeySchema=[{'AttributeName': 'userId', 'KeyType': 'HASH'},
                   {'AttributeName': 'itemId', 'KeyType': 'RANGE'}],
        AttributeDefinitions=[{'AttributeName': 'userId', 'AttributeType': 'S'},
                              {'AttributeName': 'itemId', 'AttributeType': 'S'}],
        ProvisionedThroughput={'ReadCapacityUnits': 5, 'WriteCapacityUnits': 5}
    )

    # 5. Initialize Postgres Schema
    import psycopg2
    with psycopg2.connect(postgres.get_connection_url()) as conn:
        with conn.cursor() as cur:
            cur.execute("""
                        CREATE TABLE products (
                                                  id VARCHAR(50) PRIMARY KEY,
                                                  description TEXT,
                                                  price DECIMAL(10, 2)
                        );
                        INSERT INTO products VALUES ('item123', 'Real Test Item', 19.99);
                        """)

    yield  # Run the tests

    # 6. Cleanup after all tests are done
    postgres.stop()
    localstack.stop()
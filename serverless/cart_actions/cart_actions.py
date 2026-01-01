import os
import time
from psycopg2.extras import RealDictCursor
from boto3.dynamodb.conditions import Key

try:
    from db import get_psql_connection, get_cart_table
except ImportError:
    from serverless.db_layer.db import get_psql_connection, get_cart_table

# Detect environment once
RUNTIME = os.environ.get('CLOUD_RUNTIME', 'AWS').upper()

def add_item_to_cart(user_id, item_id):
    conn = get_psql_connection()
    table_or_container = get_cart_table()

    try:
        with conn.cursor(cursor_factory = RealDictCursor) as cur:
            cur.execute("SELECT id, description, price FROM products WHERE id = %s", (item_id,))
            product = cur.fetchone()
            if not product:
                raise Exception("Item not found in catalog")

            ttl = int(time.time()) + 3600
            item = {
                'id': f"{user_id}_{item_id}",
                'itemId': str(item_id),
                'userId': str(user_id),
                'description': product['description'],
                'price': str(product['price']),
                'ttl': ttl
            }

            if RUNTIME == 'AZURE':
                table_or_container.upsert_item(body = item)
            else:
                table_or_container.put_item(Item = item)
            return {"success": True, "cart": get_cart(user_id)}
    finally:
        conn.close()

def get_cart(user_id):
    table_or_container = get_cart_table()

    if RUNTIME == 'AZURE':
        query = "SELECT * FROM c WHERE c.userId = @userId"
        parameters = [{"name": "@userId", "value": str(user_id)}]
        items = list(table_or_container.query_items(
            query = query,
            parameters = parameters,
            enable_cross_partition_query = True
        ))
    else:
        response = table_or_container.query(
            KeyConditionExpression = Key('userId').eq(str(user_id))
        )
        items = response.get('Items', [])

    return {
        "userId": user_id,
        "items": items,
        "itemCount": len(items)
    }

def remove_from_cart(user_id, item_id):
    table_or_container = get_cart_table()

    if RUNTIME == 'AZURE':
        item_id_key = f"{user_id}_{item_id}"
        table_or_container.delete_item(item = item_id_key, partition_key = str(user_id))
    else:
        table_or_container.delete_item(
            Key = {'userId': str(user_id), 'itemId': str(item_id)}
        )

    return {"success": True, "cart": get_cart(user_id)}
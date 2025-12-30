import time
from psycopg2.extras import RealDictCursor
from boto3.dynamodb.conditions import Key

try:
    # Works in Lambda
    from db import get_psql_connection, get_cart_table
except ImportError:
    # Works locally during development
    from serverless.db_layer.db import get_psql_connection, get_cart_table

def add_item_to_cart(user_id, item_id):
    """Lookup item in RDS and save to DynamoDB with 1hr TTL."""
    conn = get_psql_connection()
    table = get_cart_table()
    print(f'Adding item {item_id} to cart for user {user_id}')
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            # 1. RDS Lookup
            cur.execute("SELECT id, description, price FROM products WHERE id = %s", (item_id,))
            product = cur.fetchone()
            if not product:
                raise Exception("Item not found in catalog")
            print(f'Found item {product["id"]} in catalog')

            # 2. DynamoDB Save
            ttl = int(time.time()) + 3600
            item = {
                'itemId': item_id,
                'userId': user_id,
                'description': product['description'],
                'price': str(product['price']),
                'ttl': ttl
            }
            table.put_item(Item=item)
            print(f'Saved item {item_id} to cart for user {user_id}')
            return {"success": True, "cart": get_cart(user_id)}
    finally:
        conn.close()

def get_cart(user_id):
    """Retrieve all items for a specific user."""
    table = get_cart_table()
    
    response = table.query(
        KeyConditionExpression=Key('userId').eq(user_id)
    )
    items = response.get('Items', [])
    print(f'Found {len(items)} items in cart for user {user_id}')

    return {
        "userId": user_id,
        "items": items,
        "itemCount": len(items)
    }

def remove_from_cart(user_id, item_id):
    """Delete a specific item from the user's cart."""
    table = get_cart_table()
    table.delete_item(
        Key={'userId': user_id, 'itemId': item_id}
    )
    print(f'Removed item {item_id} from cart for user {user_id}')

    return {"success": True, "removedItemId": item_id}

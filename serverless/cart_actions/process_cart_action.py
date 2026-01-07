import json
from serverless.cart_actions.cart_actions import add_item_to_cart, get_cart, remove_from_cart

def process_cart_action(action_type, user_id, body_str):
    print(f'Processing action {action_type} for user {user_id} and body {body_str}')

    if action_type == 'add':
        body = json.loads(body_str)
        return add_item_to_cart(user_id, body['itemId'])
    elif action_type == 'removeItem':
        body = json.loads(body_str)
        return remove_from_cart(user_id, body['itemId'])
    else:
        return get_cart(user_id)
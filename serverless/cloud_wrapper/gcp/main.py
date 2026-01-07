import json
import functions_framework
from serverless.cart_actions.process_cart_action import process_cart_action

@functions_framework.http
def cart_handler(request):
    # Determine the action based on the HTTP method
    method_map = {
        "GET": "getCart",
        "POST": "add",
        "DELETE": "removeItem"
    }
    event_type = method_map.get(request.method)
    print(f'Event type {event_type}')

    result = process_cart_action(
        event_type,
        request.args.get('userId'),
        json.dumps(request.get_json(silent=True) or {})
    )
    return (
        json.dumps(result, default=str),
        200,
        {'Content-Type': 'application/json'}
    )
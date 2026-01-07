import json
import functions_framework
from serverless.cart_actions.process_cart_action import process_cart_action

@functions_framework.http
def cart_handler(request):
    # 1. Handle Preflight (OPTIONS)
    if request.method == "OPTIONS":
        headers = {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Requested-With",
            "Access-Control-Max-Age": "3600"
        }
        return ("",
                204,
                headers)

    # 2. Define CORS headers for the actual data response
    response_headers = {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
    }

    # Determine the action based on the HTTP method
    method_map = {
        "GET": "getCart",
        "POST": "add",
        "DELETE": "removeItem"
    }
    event_type = method_map.get(request.method)

    if not event_type:
        return (json.dumps({"error": "Method not allowed"}),
                405,
                response_headers)

    print(f"Event type {event_type}")

    # Process the action
    result = process_cart_action(
        event_type,
        request.args.get("userId"),
        json.dumps(request.get_json(silent=True) or {})
    )

    return (
        json.dumps(result, default = str),
        200,
        response_headers
    )
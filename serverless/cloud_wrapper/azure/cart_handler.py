import json

import azure.functions as func
from serverless.cart_actions.process_cart_action import process_cart_action

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

@app.route(route="cart", methods=["GET", "POST", "DELETE"])
def lambda_handler(req: func.HttpRequest) -> func.HttpResponse:
    # Determine the action based on the HTTP method
    method_map = {
        "GET": "getCart",
        "POST": "add",
        "DELETE": "removeItem"
    }
    event_type = method_map.get(req.method)
    print(f'Event type {event_type}')

    user_id = req.params.get('userId')
    req_body = req.get_body().decode('utf-8')
    result = process_cart_action(event_type, user_id, req_body)

    return func.HttpResponse(
        json.dumps(result, default=str),
        status_code=200,
        mimetype="application/json"
    )
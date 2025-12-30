resource "aws_apigatewayv2_api" "cart_api" {
  name          = "cart-service-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
  }
}

resource "aws_apigatewayv2_integration" "lambda_cart_int" {
  api_id           = aws_apigatewayv2_api.cart_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.cart_function.invoke_arn
  payload_format_version = "2.0"

  # Used in handler
  request_parameters = {
    "append:querystring.eventType" = "$context.httpMethod"
  }
}

# GET /cart
resource "aws_apigatewayv2_route" "get_cart" {
  api_id    = aws_apigatewayv2_api.cart_api.id
  route_key = "GET /cart"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_cart_int.id}"
}

# POST /cart (Add item)
resource "aws_apigatewayv2_route" "add_item" {
  api_id    = aws_apigatewayv2_api.cart_api.id
  route_key = "POST /cart"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_cart_int.id}"
}

# DELETE /cart (Remove item)
resource "aws_apigatewayv2_route" "remove_item" {
  api_id    = aws_apigatewayv2_api.cart_api.id
  route_key = "DELETE /cart"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_cart_int.id}"
}

resource "aws_apigatewayv2_stage" "cart_stage" {
  api_id      = aws_apigatewayv2_api.cart_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cart_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.cart_api.execution_arn}/*/*"
}
resource "aws_cognito_user_pool" "pool" {
  name = "react-cart-auth-pool"
}

resource "aws_cognito_identity_provider" "google" {
  user_pool_id  = aws_cognito_user_pool.pool.id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    authorize_scopes = "email openid profile"
    client_id = var.GOOGLE_CLIENT_ID
    client_secret = var.GOOGLE_CLIENT_SECRET
    attributes_url = "https://openidconnect.googleapis.com/v1/userinfo"
    attributes_url_add_attributes = "false"
    authorize_url = "https://accounts.google.com/o/oauth2/v2/auth"
    oidc_issuer= "https://accounts.google.com"
    token_request_method          = "POST"
    token_url = "https://oauth2.googleapis.com/token"
  }

  attribute_mapping = {
    email    = "email"
    username = "sub"
  }
}

resource "aws_cognito_user_pool_domain" "main" {
  domain = "serverless-cart-idp"
  user_pool_id = aws_cognito_user_pool.pool.id
}


resource "aws_cognito_user_pool_client" "client" {
  name = "react-app-client"
  user_pool_id = aws_cognito_user_pool.pool.id

  generate_secret = false

  supported_identity_providers = ["Google"]
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["email", "openid", "profile"]

  callback_urls = ["http://localhost:5173/"]
  logout_urls   = ["http://localhost:5173/"]

  allowed_oauth_flows_user_pool_client = true
}
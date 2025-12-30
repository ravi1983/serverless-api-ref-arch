resource "aws_codedeploy_app" "cart_app" {
  compute_platform = "Lambda"
  name             = "cart_function-deploy"
}

resource "aws_codedeploy_deployment_group" "cart_dg" {
  app_name               = aws_codedeploy_app.cart_app.name
  deployment_group_name  = "cart-production"
  deployment_config_name = "CodeDeployDefault.LambdaAllAtOnce" # Shifts 100% immediately
  service_role_arn       = aws_iam_role.codedeploy_role.arn

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }
}

resource "aws_iam_role" "codedeploy_role" {
  name = "cart-lambda-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codedeploy.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_lambda" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRoleForLambda"
  role       = aws_iam_role.codedeploy_role.name
}
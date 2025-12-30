module "infra" {
  source = "../infra"
  MY_IP = var.MY_IP
  AWS_REGION = var.AWS_REGION
  ENV = var.ENV
}

# Lambda layer
resource "aws_lambda_layer_version" "db_layer" {
  layer_name = "db_layer"
  filename   = "${path.module}/dummy.zip"

  compatible_runtimes = ["python3.12"]
  description         = "DB connection code"

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

# Cart function
resource "aws_lambda_function" "cart_function" {
  function_name = "cart_function"
  handler       = "cart_handler.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_exec_role.arn

  publish = true
  filename      = "${path.module}/dummy.zip"
  layers = [aws_lambda_layer_version.db_layer.arn]

  vpc_config {
    subnet_ids         = module.infra.private_subnets
    security_group_ids = [module.infra.lambda_sg]
  }

  environment {
    variables = {
      DATABASE_URL    = module.infra.db_address
      CART_TABLE_NAME = module.infra.cart_table_id
    }
  }

  # THIS NOW WORKS because it is a resource, not a module
  lifecycle {
    ignore_changes = [
      layers,
      filename,
      source_code_hash
    ]
  }
}

# The "Assume Role" Policy (allows Lambda to use this role)
resource "aws_iam_role" "lambda_exec_role" {
  name = "cart_function-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_lambda_alias" "cart_alias" {
  name             = "live"
  function_name    = aws_lambda_function.cart_function.function_name
  function_version = aws_lambda_function.cart_function.version

  lifecycle {
    ignore_changes = [function_version]
  }
}

# The DynamoDB Read Policy
resource "aws_iam_role_policy" "dynamodb_read" {
  name = "dynamodb-read-policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = [
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:BatchGetItem"
      ]
      Resource = [module.infra.cart_table_arn]
    },
      {
        # Necessary for Lambda to run inside a VPC
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }]
  })
}

# Standard CloudWatch logging permission
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

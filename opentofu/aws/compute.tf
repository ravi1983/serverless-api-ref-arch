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
module "cart_function" {
  source  = "terraform-aws-modules/lambda/aws"

  function_name = "cart-function"
  handler = "cart_handler.lambda_handler"
  runtime = "python3.12"
  layers = [aws_lambda_layer_version.db_layer.arn]

  create_package = false
  local_existing_package = "${path.module}/dummy.zip"
  ignore_source_code_hash = true

  vpc_subnet_ids = module.serverless-vpc.private_subnets
  vpc_security_group_ids = [module.lambda_sg.security_group_id]
  attach_network_policy = true

  environment_variables = {
    DATABASE_URL = module.item-catalog-db.db_instance_address
    CART_TABLE_NAME = module.serverless-dynamodb-cart.dynamodb_table_id
  }
}

module "lambda_sg" {
  source  = "terraform-aws-modules/security-group/aws"

  name        = "lambda-sg"
  description = "Security group for lambda functions"
  vpc_id      = module.serverless-vpc.vpc_id

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Environment = var.ENV
  }
}

# Bastion host
# psql -h item-catalog-db.cukqzuz648ai.us-east-2.rds.amazonaws.com -U item_user -d item_catalog_db
module "bastion_host" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "bastion-host"
  ami = "ami-00e428798e77d38d9"
  instance_type = "t3.micro"
  key_name = "ubuntu-dev"

  cpu_options = {}

  subnet_id  = module.serverless-vpc.public_subnets[0]
  vpc_security_group_ids = [module.bastion_sg.security_group_id]
  associate_public_ip_address = true

  user_data = <<-EOT
    #!/bin/bash
    dnf update -y
    dnf install -y postgresql15 nmap-ncat
  EOT

  tags = {
    Environment = var.ENV
  }
}


module "bastion_sg" {
  source  = "terraform-aws-modules/security-group/aws"

  name        = "bastion-sg"
  vpc_id      = module.serverless-vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "${var.MY_IP}/32"
    }
  ]

  egress_rules = ["all-all"]
}

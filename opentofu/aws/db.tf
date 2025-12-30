# Create RDS Postgres
module "item-catalog-db" {
  source = "terraform-aws-modules/rds/aws"
  identifier = "item-catalog-db"

  engine = "postgres"
  engine_version = "17.2"
  family = "postgres17"
  major_engine_version = "17"

  instance_class = "db.t4g.micro"
  allocated_storage = 10

  db_name = "item_catalog_db"
  username = "item_user"
  manage_master_user_password = true

  vpc_security_group_ids = [module.rds_sg.security_group_id]
  db_subnet_group_name = module.serverless-vpc.database_subnet_group_name

  tags = {
    Environment = var.ENV
    DBType = "Postgres"
    DataType = "ItemCatalog"
  }
}

module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"

  name = "rds-sg"
  vpc_id = module.serverless-vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      rule = "postgresql-tcp" # Automatically sets port 5432/TCP
      source_security_group_id = module.lambda_sg.security_group_id
    },
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = module.bastion_sg.security_group_id
      description              = "PostgreSQL access from Bastion"
    }
  ]
}

# Create DynamoDB for cart and orders
module "serverless-dynamodb-cart" {
  source = "terraform-aws-modules/dynamodb-table/aws"

  name = "cart"
  hash_key = "userId"

  billing_mode = "PAY_PER_REQUEST"
  ttl_attribute_name = "ttl"
  ttl_enabled = true

  attributes = [
    {name = "userId", type="S"}
  ]
}

output "rds_sg_id" {
  value = module.rds_sg.security_group_id
}

output "lambda_sg" {
  value = module.lambda_sg.security_group_id
}
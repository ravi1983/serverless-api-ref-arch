module "serverless-vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "serverless-vpc"
  cidr  = "10.0.0.0/16"

  azs = ["${var.AWS_REGION}a", "${var.AWS_REGION}b", "${var.AWS_REGION}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = true
  map_public_ip_on_launch = true

  # Needed to launch DBs in this VPC. Private subnet same as DB subnet group.
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24"]
  create_database_subnet_group = true


  tags = {
    Environment = var.ENV
    AppType = "serverless"
  }
}

output "vpc_id" {
  value = module.serverless-vpc.vpc_id
  description = "The ID of the serverless VPC"
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.serverless-vpc.private_subnets
}

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
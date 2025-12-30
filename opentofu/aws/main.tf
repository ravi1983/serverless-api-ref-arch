module "compute_layer" {
  source     = "./compute"
  MY_IP = var.MY_IP
  AWS_REGION = var.AWS_REGION
  ENV = var.ENV
}

module "infra_layer" {
  source     = "./infra"
  MY_IP = var.MY_IP
  AWS_REGION = var.AWS_REGION
  ENV = var.ENV
}
module "serverless-vpc" {
  source = "terraform-google-modules/network/google"

  network_name = "serverless-vpc"
  project_id = var.PROJECT_ID
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name = "serverless-subnet"
      subnet_ip = "10.1.0.0/16"
      subnet_region = var.REGION
      description = "Subnet for cloud function and cloud SQL"

      subnet_private_access = "true"
    }
  ]
}

module "cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"

  name = "serverless-router"
  project_id = var.PROJECT_ID
  region  = var.REGION
  network = module.serverless-vpc.network_name

  nats = [
    {
      name = "serverless-nat"
      nat_ip_allocate_option = "AUTO_ONLY"
      source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
    }
  ]
}
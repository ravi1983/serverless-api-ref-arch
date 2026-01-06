resource "google_compute_global_address" "google_service_range" {
  name = "google-service-range"
  purpose = "VPC_PEERING"
  address_type = "INTERNAL"
  prefix_length = 16

  network = module.serverless-vpc.network_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = module.serverless-vpc.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.google_service_range.name]
}

resource "google_sql_database" "database" {
  name     = "item_catalog_db"
  instance = google_sql_database_instance.cart-db-instance.name
}

resource "google_sql_user" "users" {
  name     = "db-user"
  instance = google_sql_database_instance.cart-db-instance.name
  password = var.DB_PASSWORD
}

resource "google_sql_database_instance" "cart-db-instance" {
  name = "cart-db-instance"
  database_version = "POSTGRES_15"
  region = var.REGION

  deletion_protection = false

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled = false
      private_network = module.serverless-vpc.network_id
      enable_private_path_for_google_cloud_services = true
    }
  }
}

resource "google_firestore_database" "cart" {
  project     = var.PROJECT_ID
  name        = "cart"
  location_id = var.REGION
  type        = "FIRESTORE_NATIVE"

  delete_protection_state = "DELETE_PROTECTION_DISABLED"
  deletion_policy = "DELETE"
}
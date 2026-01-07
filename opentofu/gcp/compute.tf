resource "google_storage_bucket" "function_bucket" {
  name = "${var.PROJECT_ID}-function-source"
  location = var.REGION
  uniform_bucket_level_access = true
}

data "archive_file" "dummy_zip" {
  type        = "zip"
  output_path = "${path.module}/dummy.zip"

  source {
    content  = "def cart_handler(request): return 'Seed code running'"
    filename = "main.py"
  }
}
resource "google_storage_bucket_object" "dummy_zip_object" {
  name   = "dummy.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.dummy_zip.output_path
}

resource "google_vpc_access_connector" "vpc-connector" {
  name          = "vpc-connector"
  region        = var.REGION
  ip_cidr_range = "10.8.0.0/28"
  network       = module.serverless-vpc.network_name

  max_instances = "3"
  min_instances = "2"
}

resource "google_service_account" "cart-function-sa" {
  account_id   = "cart-function-sa"
  display_name = "Service Account for Cart Cloud Function"
  project      = var.PROJECT_ID
}

resource "google_cloudfunctions2_function" "cart_function" {
  # provider    = google-beta
  name        = "cart-function"
  location    = var.REGION
  project     = var.PROJECT_ID
  description = "Cart computation function"

  build_config {
    runtime     = "python312"
    entry_point = "cart_handler"

    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name
        object = google_storage_bucket_object.dummy_zip_object.name
      }
    }
  }

  service_config {
    max_instance_count = 10
    available_memory   = "256Mi"
    timeout_seconds    = 60

    environment_variables = {
      CLOUD_RUNTIME = "GCP"

      DATABASE_URL = google_sql_database_instance.cart-db-instance.private_ip_address
      DB_USER = google_sql_user.users.name
      DB_PASSWORD = var.DB_PASSWORD
      CART_TABLE_NAME = google_firestore_database.cart.name
    }

    # Authenticated by IAM
    ingress_settings = "ALLOW_ALL"

    # Direct egress connection is the modern way, but PITA to delete.
    # Creating VPC connector for ease of development
    vpc_connector = google_vpc_access_connector.vpc-connector.id
    vpc_connector_egress_settings = "ALL_TRAFFIC"
    # direct_vpc_network_interface {
    #   network    = module.serverless-vpc.network_name
    #   subnetwork = module.serverless-vpc.subnets_names[0]
    # }
  }

  lifecycle {
    ignore_changes = [
      # Ignore code updates (ZIP object and generation)
      build_config[0].source[0].storage_source[0].object,
      build_config[0].source[0].storage_source[0].generation,
    ]
  }
}


# API Gateway
resource "google_api_gateway_api" "cart_api" {
  provider = google-beta
  api_id   = "cart-api"
  project  = var.PROJECT_ID
}

resource "google_api_gateway_gateway" "gw" {
  provider     = google-beta
  api_config   = google_api_gateway_api_config.cart_cfg.id
  gateway_id   = "cart-gateway"
  region       = var.REGION
  project      = var.PROJECT_ID
}

locals {
  openapi_spec = templatefile("${path.module}/api-spec/openapi.yml", {
    FUNCTION_URL = google_cloudfunctions2_function.cart_function.url
  })
}

resource "google_api_gateway_api_config" "cart_cfg" {
  provider      = google-beta
  api           = google_api_gateway_api.cart_api.api_id
  api_config_id = "cart-config-${md5(local.openapi_spec)}"
  project       = var.PROJECT_ID

  gateway_config {
    backend_config {
      google_service_account = google_service_account.api_gateway_sa.email
    }
  }

  # Ideally should be part of CI
  openapi_documents {
    document {
      path = "openapi.yaml"
      contents = base64encode(local.openapi_spec)
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_service_account" "api_gateway_sa" {
  account_id   = "cart-api-gateway-sa"
  display_name = "Service Account for Cart API Gateway"
  project      = var.PROJECT_ID
}

resource "google_cloud_run_service_iam_member" "invoker" {
  project  = google_cloudfunctions2_function.cart_function.project
  location = google_cloudfunctions2_function.cart_function.location
  service  = google_cloudfunctions2_function.cart_function.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.api_gateway_sa.email}"
}

output "gateway_url" {
  value = "https://${google_api_gateway_gateway.gw.default_hostname}"
  description = "The base URL for your cart API"
}
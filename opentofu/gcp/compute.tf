resource "google_vpc_access_connector" "vpc-connector" {
  name          = "vpc-connector"
  region        = var.REGION
  ip_cidr_range = "10.8.0.0/28"
  network       = module.serverless-vpc.network_name

  max_instances = "3"
  min_instances = "2"
}

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


resource "google_cloudfunctions2_function" "cart_function" {
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

    vpc_connector = google_vpc_access_connector.vpc-connector.id
    ingress_settings = "ALLOW_INTERNAL_ONLY"
    vpc_connector_egress_settings = "ALL_TRAFFIC"
  }

  lifecycle {
    ignore_changes = [
      # Ignore code updates (ZIP object and generation)
      build_config[0].source[0].storage_source[0].object,
      build_config[0].source[0].storage_source[0].generation,
    ]
  }
}

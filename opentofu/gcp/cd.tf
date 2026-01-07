resource "google_clouddeploy_delivery_pipeline" "cart_pipeline" {
  name     = "cart-function-pipeline"
  location = var.REGION
  project  = var.PROJECT_ID

  serial_pipeline {
    stages {
      target_id = "cart-deployment"
    }
  }
}

resource "google_clouddeploy_target" "cart-deployment" {
  name     = "cart-deployment"
  location = var.REGION
  project  = var.PROJECT_ID

  run {
    location = "projects/${var.PROJECT_ID}/locations/${var.REGION}"
  }
}
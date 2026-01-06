variable "PROJECT_ID" {
  default = "serverless-project-143"
}

variable "REGION" {}

variable "DB_PASSWORD" {
  description = "Password for the Cloud SQL database user"
  type        = string
  sensitive   = true
}
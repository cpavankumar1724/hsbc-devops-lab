variable "project_id" {
  description = "Your GCP free-tier project ID"
  type        = string
}

variable "region" {
  description = "GCP region to deploy into"
  type        = string
  default     = "us-central1"
}

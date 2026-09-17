terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Autopilot mode is used deliberately: it removes node-pool management
# so you can focus the week's lab time on Kubernetes objects and pipelines
# rather than node sizing. Standard GKE with manual node pools is worth
# doing separately once you have more time, since HSBC may run Standard mode.
resource "google_container_cluster" "lab_cluster" {
  name             = "hsbc-lab-cluster"
  location         = var.region
  enable_autopilot = true

  network    = var.vpc_name
  subnetwork = var.subnet_name
}

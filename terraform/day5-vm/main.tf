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

resource "google_compute_instance" "ansible_target" {
  name         = "ansible-target-vm"
  machine_type = "e2-small"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "hsbc-lab-vpc"
    subnetwork = "lab-subnet-a"
    # Still no public IP — you will reach it with "gcloud compute ssh"
    # which tunnels through IAP automatically.
  }

  metadata = {
    enable-oslogin = "TRUE"
  }
}

output "instance_name" {
  value = google_compute_instance.ansible_target.name
}

output "zone" {
  value = google_compute_instance.ansible_target.zone
}

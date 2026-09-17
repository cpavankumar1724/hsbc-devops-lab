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

resource "google_compute_network" "lab_vpc" {
  name                    = "hsbc-lab-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet_a" {
  name          = "lab-subnet-a"
  ip_cidr_range = "10.10.1.0/24"
  region        = var.region
  network       = google_compute_network.lab_vpc.id
}

resource "google_compute_subnetwork" "subnet_b" {
  name          = "lab-subnet-b"
  ip_cidr_range = "10.10.2.0/24"
  region        = var.region
  network       = google_compute_network.lab_vpc.id
}

# Allow internal traffic between the two subnets only
resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.lab_vpc.id
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["10.10.1.0/24", "10.10.2.0/24"]
}

# Allow SSH only via Identity-Aware Proxy range, not the open internet
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh"
  network = google_compute_network.lab_vpc.id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
}

resource "google_compute_instance" "vm_a" {
  name         = "lab-vm-a"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_a.id
    # No external IP — access via IAP tunnel only, which is the SecOps-friendly pattern
  }
}

resource "google_compute_instance" "vm_b" {
  name         = "lab-vm-b"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_b.id
  }
}

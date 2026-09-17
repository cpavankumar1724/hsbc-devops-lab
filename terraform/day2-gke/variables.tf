variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "vpc_name" {
  description = "Name of the VPC created in Day 1 (hsbc-lab-vpc)"
  type        = string
  default     = "hsbc-lab-vpc"
}

variable "subnet_name" {
  description = "Name of the subnet created in Day 1 to run the cluster in"
  type        = string
  default     = "lab-subnet-a"
}

output "vpc_name" {
  value = google_compute_network.lab_vpc.name
}

output "vm_a_internal_ip" {
  value = google_compute_instance.vm_a.network_interface[0].network_ip
}

output "vm_b_internal_ip" {
  value = google_compute_instance.vm_b.network_interface[0].network_ip
}

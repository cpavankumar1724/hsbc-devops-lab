output "cluster_name" {
  value = google_container_cluster.lab_cluster.name
}

output "cluster_endpoint" {
  value     = google_container_cluster.lab_cluster.endpoint
  sensitive = true
}

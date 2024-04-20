output "cdn_subnetwork_id" {
  value = google_compute_subnetwork.private-subnet.id
}

output "cdn_subnetwork_cidr" {
  value = google_compute_subnetwork.private-subnet.ip_cidr_range
}


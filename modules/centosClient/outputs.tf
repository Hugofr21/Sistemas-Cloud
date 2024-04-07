 output "machine_hostname" {
  value = google_compute_instance.node04client.name
}

output "machine_ip" {
  value = google_compute_instance.node04client.network_interface[0].network_ip
} 
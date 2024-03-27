 output "machine_hostname" {
  value = google_compute_instance.node04.name
}

output "machine_ip" {
  value = google_compute_instance.node04.network_interface[0].network_ip
} 
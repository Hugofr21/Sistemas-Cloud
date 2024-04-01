 output "machine_hostname" {
  value = google_compute_instance.node03.name
}

output "machine_ip" {
  value = google_compute_instance.node03.network_interface[0].network_ip
} 
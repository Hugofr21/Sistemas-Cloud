resource "google_compute_firewall" "this" {
  name    = "cdn-firewall"
  network = google_compute_network.this.id
  
  description = "Creates firewall rule targeting tagged instances"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  target_tags = ["tcp", "http-server"]

  allow {
    protocol = "ICMP"
  }

  allow {
    protocol = "TCP"
    ports    = ["22", "80", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
}
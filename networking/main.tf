resource "google_compute_network" "this" {
  name                    = "cdn-network"
  auto_create_subnetworks = false
}
resource "google_compute_subnetwork" "private-subnet" {
  name                     = "private-subnet"
  ip_cidr_range            = "172.16.0.0/27"
  network                  = google_compute_network.this.id
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "public_network" {
  name                     = "public-subnet"
  ip_cidr_range            = "200.0.0.0/27"
  network                  = google_compute_network.this.id
  private_ip_google_access = true
} 


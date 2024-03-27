# NAT ROUTER
resource "google_compute_router" "this" {
  name    = "cdn-router"
  region  = google_compute_subnetwork.private-subnet.region
  network = google_compute_network.this.id
}

resource "google_compute_router_nat" "this" {
  name                               = "cdn-router-nat"
  router                             = google_compute_router.this.name
  region                             = google_compute_router.this.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.private-subnet.name
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}
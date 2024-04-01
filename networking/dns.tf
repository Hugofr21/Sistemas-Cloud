resource "google_dns_managed_zone" "dns_zone" {
  name        = "videos-api-zone"
  dns_name    = "videos-api.cloud.com"
  description = "DNS zone for the videos API"
  dnssec_config {
    state = "off"
  }
  visibility = "public"
}

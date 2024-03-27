resource "google_dns_managed_zone" "dns_zone" {
  name        = "example-zone-name"
  dns_name    = "cdn.cloud.com."
  description = "DNS zone for cdn.cloud.com"
  dnssec_config {
    state = "off"
  }
  visibility = "public"
}
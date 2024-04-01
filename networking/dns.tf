resource "google_dns_managed_zone" "dns_zone" {
  name        = "videos-api-zone"
  dns_name    = "videos-api.example.com."
  description = "DNS zone for the videos API"
  dnssec_config {
    state = "off"
  }
  visibility = "public"
}

# resource "google_dns_record_set" "a_record" {
#   name    = "videos-api.example.com."
#   type    = "A"
#   ttl     = 300
#   managed_zone = google_dns_managed_zone.dns_zone.name
#   rrdatas = ["IP_DO_SERVIDOR"] 
# }

resource "google_dns_record_set" "cname_record" {
  name    = "www.videos-api.example.com."
  type    = "CNAME"
  ttl     = 300
  managed_zone = google_dns_managed_zone.dns_zone.name
  rrdatas = ["videos-api.example.com."]
}
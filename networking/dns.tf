resource "google_dns_managed_zone" "dns_zone" {
  name        = "videos-api-zone"
  dns_name    = "ns1video22world.com."
  description = "DNS zone for the videos API"
  dnssec_config {
    state = "off"
  }
  visibility = "public"
}

resource "google_dns_record_set" "website_record" {
  name    = "blog.ns1video22world.com"
  type    = "A" 
  ttl     = 300
  
  managed_zone = google_dns_managed_zone.dns_zone.name
  rrdatas = [google_compute_global_address.cdn.address]
}


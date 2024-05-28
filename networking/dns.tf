resource "google_dns_managed_zone" "dns_zone" {
  name        = "videos-api-zone"
  dns_name    = "videos-api.example.com."
  description = "DNS zone for the videos API"
  dnssec_config {
    state = "off"
  }
  visibility = "public"
}

# Registo "A" se estiver apontando para um endereço IP, "CNAME" se estiver apontando para outro domínio
resource "google_dns_record_set" "website_record" {
  name    = "www.videos-api.example.com."
  type    = "A" 
  ttl     = 300
  
  managed_zone = google_dns_managed_zone.dns_zone.name
  rrdatas = [google_compute_global_address.cdn.address]
}


resource "google_compute_backend_bucket" "website" {
  provider    = google
  name        = "website-backend"
  description = "Contains files needed by the website"
  bucket_name = google_storage_bucket.video_cloud_systems.name
  enable_cdn  = true
}

resource "google_compute_managed_ssl_certificate" "website" {
  name     = "website-cert"
  managed {
    domains = [google_dns_record_set.cname_record.name]
  }
}

resource "google_compute_url_map" "website" {
  provider        = google
  name            = "website-url-map"
  default_service = google_compute_backend_bucket.website.self_link
}

resource "google_compute_target_https_proxy" "website" {
  provider         = google
  name             = "website-target-proxy"
  url_map          = google_compute_url_map.website.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.website.self_link]
}

resource "google_compute_global_forwarding_rule" "website" {
  provider              = google
  name                  = "website-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.website.address
  ip_protocol           = "TCP"
  port_range            = "443"
  target                = google_compute_target_https_proxy.website.self_link
}

resource "google_compute_ssl_policy" "cdn_ssl_policy" {
  provider = google
  name     = "website-ssl-policy"
}

resource "google_compute_backend_bucket" "cdn_backend_bucket" {
  provider    = google
  name        = "cdn-backend-bucket"
  description = "Backend bucket for CDN"
  bucket_name = google_storage_bucket.video_cloud_systems.name
  enable_cdn  = true
}

resource "google_compute_url_map" "cdn_url_map" {
  provider        = google
  name            = "cdn-url-map"
  default_service = google_compute_backend_bucket.cdn_backend_bucket.self_link
}

resource "google_compute_target_http_proxy" "cdn_proxy" {
  provider = google
  name     = "cdn-target-proxy"
  url_map  = google_compute_url_map.cdn_url_map.self_link
}

resource "google_compute_global_forwarding_rule" "cdn" {
  provider              = google
  name                  = "cdn-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.cdn.address
  ip_protocol           = "TCP"
  port_range            = "443"
  target                = google_compute_target_http_proxy.cdn_proxy.self_link
}
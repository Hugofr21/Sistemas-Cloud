# resource "google_dns_set" "dns" {
#     name = "cdn.example.com"
#     type = "A"
#     ttl = 300
#     managed_zone = "europe-west1-c" 
#     rrdatas = [google_compute_global_forwarding_rule.cdn_forwarding_rule.ip_address]
  
# }

# resource "google_compute_global_forwarding_rule" "cdn_forwarding_rule" {
#   name       = "cdn_forwarding_rule"
#   target     = ""
#   port_range = ""
# }

# resource "google_compute_url_map" "cdn_url_map" {
#   name = "cdn_url_map"
#   default_service = ""
#    default_route_action {

#    }
# }

# resource "goole_compute_target_http_proxy" "cdn_targtet_proxy" {
#   name = "cdn_targtet_proxy"
#   url_map = google_compute_url_map.id
# }
# resource "tls_private_key" "ssl" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# // CSR
# resource "tls_cert_request" "certificate_request" {
#   private_key_pem = tls_private_key.ssl.private_key_pem
#   subject {
#     common_name  = "video-cloud"
#     organization = "Cloud Project"
#   }
# }


# //CERT
# resource "google_compute_ssl_certificate" "self_signed_cert" {
#   name        = "certificate"
#   private_key = "${path.module}/ssl_private_key.pem"
#   certificate = "${path.module}/ssl_certificate.pem"
# }

# resource "local_file" "private_key_file" {
#   filename = "${path.module}/ssl/ssl_private_key.pem"
#   content  = tls_private_key.ssl.private_key_pem
# }

# resource "local_file" "certificate_file" {
#   filename = "${path.module}/sl/ssl_certificate.pem"
#   content  = tls_cert_request.certificate_request.cert_request_pem
# }

# //key private
# output "ssl_private_key" {
#   value     = tls_private_key.ssl.private_key_pem
#   sensitive = true
# }

# output "ssl_certificate" {
#   value     = tls_cert_request.certificate_request.cert_request_pem
#   sensitive = true
# }


# Generate SSL Private Key
resource "tls_private_key" "ssl" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Generate CSR
resource "tls_cert_request" "certificate_request" {
  private_key_pem = tls_private_key.ssl.private_key_pem
  subject {
    common_name  = "video-cloud"
    organization = "Cloud Project"
  }
}

# Self-signed certificate is generated using the CSR
resource "tls_self_signed_cert" "self_signed_cert" {
 ## key_algorithm   = tls_private_key.ssl.algorithm
  private_key_pem = tls_private_key.ssl.private_key_pem
  subject {
    common_name  = "video-cloud"
    organization = "Cloud Project"
  }
  validity_period_hours = 60000
    allowed_uses           = ["digital_signature", "key_encipherment"]
}

# Export SSL Private Key to File
resource "local_file" "private_key_file" {
  filename = "${path.module}/ssl/ssl_private_key.pem"
  content  = tls_private_key.ssl.private_key_pem
}

# Export SSL Certificate to File
resource "local_file" "certificate_file" {
  filename = "${path.module}/ssl/ssl_certificate.pem"
  content  = tls_self_signed_cert.self_signed_cert.cert_pem
}


output "algorithm" {
  value = "${var.algorithm}"
}


# Output SSL Private Key
output "ssl_private_key" {
  value     = tls_private_key.ssl.private_key_pem
  sensitive = true
}

# Output SSL Certificate
output "ssl_certificate" {
  value     = tls_self_signed_cert.self_signed_cert.cert_pem
  sensitive = true
}

#generate ssh key
resource "tls_private_key" "cdn" {
  algorithm = "ED25519"
  rsa_bits  = 4096
}

resource "local_file" "cdn_public_key" {
  filename        = "server_public_openssh"
  content         = trimspace(tls_private_key.cdn.public_key_openssh)
  file_permission = "0400"
}

resource "local_sensitive_file" "cdn_private_key" {
  filename        = "server_private_openssh"
  # IMPORTANT: Newline is required at end of open SSH private key file
  content         = tls_private_key.cdn.private_key_openssh
  file_permission = "0400"
}
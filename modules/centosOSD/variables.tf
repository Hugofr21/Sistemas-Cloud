

variable "gce_zone" {
  type        = string
  description = "Google Cloud zone"
}

variable "gce_tags" {
  type        = list(string)
  description = "Google Cloud machine tags"
}

variable "gce_service_account_email" {
  type        = string
  description = "Google Cloud service account email"
}

variable "gce_service_account_scopes" {
  type        = list(string)
  description = "Google Cloud service account scopes"
}

variable "cdn_subnetwork_id" {
  type        = string
  description = "CDN network id"
}

variable "cdn_subnetwork_cidr" {
  type        = string
  description = "CDN network cidr"
}

variable "cdn_public_key" {
  type        = string
  description = "ssh public key for cdn internal configuration (base64 encoded)"
}
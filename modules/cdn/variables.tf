variable "google_cloud_zone" {
  type        = string
  description = "Google Cloud zone"
}

variable "google_cloud_tags" {
  type        = list(string)
  description = "Google Cloud machine tags"
}

variable "google_cloud_service_account_email" {
  type        = string
  description = "Google Cloud service account email"
}

variable "google_cloud_service_account_scopes" {
  type        = list(string)
  description = "Google Cloud service account scopes"
}

variable "cdn_subnetwork_id" {
  type        = string
  description = "cdn network id"
}

variable "cdn_subnetwork_cidr" {
  type        = string
  description = "cdn network cidr"
}

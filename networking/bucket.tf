
resource "google_storage_bucket" "video_cloud_systems" {
  name          = "video-cloud-systems"
  location      = "europe-west1"
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
  }

  retention_policy {
    retention_period = 604800 # 7 dias em segundos
  }
}
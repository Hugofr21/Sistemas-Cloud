
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
    retention_period = 604800 
  }

  website {
       main_page_suffix = "index.html"
       not_found_page   = "404.html"
  }
}


resource "google_compute_backend_bucket" "video_cloud_systems_backend" {
  name             = "video-cloud-systems-backend"
  bucket_name      = google_storage_bucket.video_cloud_systems.name
  enable_cdn       = true
}

resource "google_compute_global_address" "website" {
  name     = "website-lb-ip"
}
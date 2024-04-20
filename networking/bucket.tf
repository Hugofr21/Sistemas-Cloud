
resource "google_storage_bucket" "bucket_cloud_systems" {
  name          = "bucket_cloud_systems"
  location      = "europe-west3"
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

  # retention_policy {
  #   retention_period = 604800
  # }

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}


resource "google_compute_backend_bucket" "video_cloud_systems_backend" {
  name        = "video-cloud-systems-backend"
  bucket_name = google_storage_bucket.bucket_cloud_systems.name
  enable_cdn  = true
}

resource "google_compute_global_address" "website" {
   provider = google
  name       = "website-lb-ip"
  ip_version = "IPV4"
}

resource "google_compute_global_address" "cdn" {
  provider = google
  name     = "cdn-lb-ip"
  ip_version = "IPV4"
}

resource "google_storage_bucket_object" "static_web_src" {
  name = "index.html"
  source = "./web/static/index.html"
  bucket = google_storage_bucket.bucket_cloud_systems.name

  
}
resource "google_storage_bucket_object" "video1" {
  name   = "video1.mp4"
  source = "./web/static/video1.mp4"
  bucket = google_storage_bucket.bucket_cloud_systems.name
}
resource "google_storage_bucket_object" "video2" {
  name   = "video2.mp4"
  source = "./web/static/video2.mp4"
  bucket = google_storage_bucket.bucket_cloud_systems.name
}

resource "google_storage_bucket_iam_member" "all_users_viewers" {
  bucket = google_storage_bucket.bucket_cloud_systems.name
  role   = "roles/storage.legacyObjectReader"
  member = "allUsers"
}

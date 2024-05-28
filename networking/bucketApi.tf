resource "google_storage_bucket" "bucket_cloud_api" {
  name          = "bucket-cloud-api"
  location      = "europe-west3"
  storage_class = "STANDARD"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "api_zip" {
  name   = "api-spring.zip"
  source = "./api/video-cloud.zip"
  bucket = google_storage_bucket.bucket_cloud_api.name
}



resource "google_storage_bucket_iam_member" "all_users_api" {
  bucket = google_storage_bucket.bucket_cloud_api.name
  role   = "roles/storage.legacyObjectReader"
  member = "allUsers"
}

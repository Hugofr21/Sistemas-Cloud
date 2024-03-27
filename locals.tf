locals {
  google_cloud_settings = {
    zone = "europe-west1-c"
    tags = ["http-server","tcp"]
    service_account = {
      email  = "terraform-sa@adm-project-402621.iam.gserviceaccount.com"
      scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    }
  }
}
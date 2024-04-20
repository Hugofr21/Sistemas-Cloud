locals {
  google_cloud_settings = {
    zone = "europe-west3-c"
    tags = ["http-server","tcp"]
    service_account = {
      email  = "681980934210-compute@developer.gserviceaccount.com"
      scopes = [
              "https://www.googleapis.com/auth/devstorage.read_only", 
              "https://www.googleapis.com/auth/logging.write", 
              "https://www.googleapis.com/auth/monitoring.write",
              "https://www.googleapis.com/auth/service.management.readonly",
              "https://www.googleapis.com/auth/servicecontrol", 
              "https://www.googleapis.com/auth/trace.append"
        ]
    }
  }
}
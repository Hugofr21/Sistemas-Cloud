provider "google" {
  project     = "adscloud-416312"
  credentials = file("./credentials/key.json")
  region      = "europe-west1"
  zone        = "europe-west1-b"
}

provider "tls" {
}
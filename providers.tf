provider "google" {
  project     = "cloudadministration"
  credentials = file("./credentials/key.json")
  region      = "europe-west1"
  zone        = "europe-west1-b"
}
provider "google-beta" {
  credentials = file("./credentials/key.json")
}

provider "tls" {
}


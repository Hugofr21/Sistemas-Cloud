provider "google" {
  project     = "cloudadministrationsystems"
  credentials = file("./credentials/key.json")
  region      = "europe-west3"
  zone        = "europe-west3-b"
}
provider "google-beta" {
  credentials = file("./credentials/key.json")
}

provider "tls" {
}


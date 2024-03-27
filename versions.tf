terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.79.0"  
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
  }
}
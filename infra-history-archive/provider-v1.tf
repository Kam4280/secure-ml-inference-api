terraform {
  # Enforces a modern Terraform engine baseline
  required_version = ">= 1.5.0"
  
  # Pinning the official Google Cloud provider to prevent breaking changes
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0" # Leverages the newest production capabilities
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
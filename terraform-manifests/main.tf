terraform {
  required_version = ">= 1.0"
  
  backend "gcs" {
    bucket = "shaghaghi-test-tfstate" # The exact name of the bucket you created in Step 3A
    prefix = "terraform/state"        # The folder path inside the bucket
  }
}

# 1. Enable Required Cloud APIs Automatically (Cloud Run Removed)
resource "google_project_service" "services" {
  for_each = toset([
    "container.googleapis.com",
    "iam.googleapis.com"
  ])
  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

# 2. Deploy Google Kubernetes Engine (Autopilot Secure Mode)
resource "google_container_cluster" "gke_cluster" {
  name             = var.cluster_name
  location         = var.region
  enable_autopilot = true
  project          = var.project_id

  depends_on = [google_project_service.services]
}
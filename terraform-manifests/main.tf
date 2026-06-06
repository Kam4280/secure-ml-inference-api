terraform {
  required_version = ">= 1.0"
  
  backend "gcs" {
    bucket = "shaghaghi-test-tfstate" # The exact name of the bucket you created in Step 3A
    prefix = "terraform/state"        # The folder path inside the bucket
  }
}

provider "google" {
  project = "shaghaghi-test"
  region  = "us-central1"
}

# ... keep all your existing resource blocks (GKE, Cloud Run, etc.) exactly as they were below ...

# 1. Enable Required Cloud APIs Automatically
resource "google_project_service" "services" {
  for_each = toset([
    "container.googleapis.com",
    "run.googleapis.com",
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

# 3. Deploy Cloud Run Service Container Framework
resource "google_cloud_run_v2_service" "cloud_run_api" {
  name     = var.cloud_run_name
  location = var.region
  project  = var.project_id

  template {
    containers {
      # Instantiates with a clean base container; the CD pipeline will overwrite this instantly
      image = "us-central1-docker.pkg.dev/shaghaghi-test/secure-ml-inference-registry/api:latest"
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image
    ]
  }

  depends_on = [google_project_service.services]
}

# 4. Bind Public Routing Ingress for Cloud Run Evaluation
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = var.project_id
  location = google_cloud_run_v2_service.cloud_run_api.location
  name     = google_cloud_run_v2_service.cloud_run_api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
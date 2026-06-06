# ==========================================
# 1. APPLICATION RUNTIME ASSETS
# ==========================================

# Secure Container Registry with Tag Immutability
resource "google_artifact_registry_repository" "ml_api_repo" {
  location      = var.region
  repository_id = "secure-ml-inference-registry"
  description   = "Hardened Docker images for secure ML inference APIs"
  format        = "DOCKER"

  docker_config {
    immutable_tags = true
  }
}

# Cryptographic Numeric ID Generator for Vertex AI
resource "random_id" "endpoint_id" {
  byte_length = 4
}

# Fully Managed Inference Infrastructure Endpoint
resource "google_vertex_ai_endpoint" "inference_endpoint" {
  name         = substr(random_id.endpoint_id.dec, 0, 10)
  display_name = "secure-ml-endpoint"
  location     = var.region
}

# ==========================================
# 2. WORKLOAD IDENTITY FEDERATION (THE SECURITY BRIDGE)
# ==========================================

# The Identity Pool: A logical container for external identities
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for secure GitHub Actions OIDC token exchange"
}

# The Provider: Maps the token signatures coming from GitHub to GCP attributes
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Provider"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  # Attribute Mapping: Converts GitHub claims into standardized GCP attributes
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  # FIX 1: Explicit Attribute Condition Validation Gate
  # This tells the provider to ONLY accept tokens if the repository claim starts with your GitHub profile
  attribute_condition = "assertion.repository.startsWith('Kam4280/')"
}

# ==========================================
# 3. IDENTITY IMPERSONATION BOUNDARIES
# ==========================================

# The Service Account that executes our actual deployment tasks
resource "google_service_account" "pipeline_deployer" {
  account_id   = "mlops-pipeline-deployer"
  display_name = "MLOps Pipeline Execution Account"
}

# The Security Policy: Allows ONLY your specific GitHub Repo to assume this account
resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.pipeline_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/Kam4280/secure-ml-inference-api"
}

# ==========================================
# 4. EXPLICIT LEAST-PRIVILEGE PERMISSIONS
# ==========================================

# Grant Artifact Registry Writer access to push Docker images
resource "google_artifact_registry_repository_iam_member" "registry_writer" {
  location   = google_artifact_registry_repository.ml_api_repo.location
  repository = google_artifact_registry_repository.ml_api_repo.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.pipeline_deployer.email}"
}

# FIX 2: Corrected Vertex AI Role targeting string to official GCP spec
resource "google_project_iam_member" "vertex_developer" {
  project = var.project_id
  role    = "roles/aiplatform.admin"
  member  = "serviceAccount:${google_service_account.pipeline_deployer.email}"
}
variable "project_id" {
  type        = string
  description = "The target unique Google Cloud Project ID where infrastructure will reside."
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "The regional boundary for resource localization and data residency compliance."
}
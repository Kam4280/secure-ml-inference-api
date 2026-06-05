variable "project_id" {
  type    = string
  default = "shaghaghi-test"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "cluster_name" {
  type    = string
  default = "secure-ml-gke-cluster"
}

variable "cloud_run_name" {
  type    = string
  default = "secure-ml-inference-api"
}
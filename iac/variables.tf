variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Kubeconfig context to use (empty = current)"
  type        = string
  default     = ""
}

variable "namespace" {
  description = "OKD project (namespace) where everything is deployed"
  type        = string
  default     = "endre-cloud-based-distributed-systems-laboratory"
}

variable "app_name" {
  description = "Logical name of the app (used as resource name prefix)"
  type        = string
  default     = "my-app"
}

variable "app_host" {
  description = "Public hostname for the Route"
  type        = string
  default     = "my-app-endre-cloud-based-distributed-systems-laboratory.apps.okd.fured.cloud.bme.hu"
}

variable "git_repo_url" {
  description = "Git repo URL that the BuildConfig clones"
  type        = string
  default     = "https://github.com/endreglocker/Cloud-based-Distributed-Systems-Laboratory.git"
}

variable "git_branch" {
  description = "Git branch to build from"
  type        = string
  default     = "main"
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "django"
}

variable "postgres_password" {
  description = "PostgreSQL password (generate a strong one per env)"
  type        = string
  sensitive   = true
}

variable "postgres_database" {
  description = "PostgreSQL database name"
  type        = string
  default     = "myappdb"
}

variable "postgres_image" {
  description = "PostgreSQL container image (OpenShift-compatible, random UID friendly)"
  type        = string
  default     = "quay.io/sclorg/postgresql-15-c9s:latest"
}

variable "postgres_storage_size" {
  description = "Database PVC size"
  type        = string
  default     = "1Gi"
}

variable "media_storage_size" {
  description = "Media uploads PVC size"
  type        = string
  default     = "5Gi"
}

variable "app_replicas" {
  description = "Number of app replicas"
  type        = number
  default     = 1
}

variable "app_port" {
  description = "Port the Django app listens on"
  type        = number
  default     = 8000
}
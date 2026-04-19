terraform {
  required_version = ">= 1.6.0"

  # Remote state stored as a Secret inside the project namespace.
  # Without this, every GitHub Actions run would start with empty state
  # (the runner's filesystem is ephemeral) and try to recreate resources
  # that already exist in the cluster.
  backend "kubernetes" {
    secret_suffix = "tfstate"
    namespace     = "endre-cloud-based-distributed-systems-laboratory"
    config_path   = "~/.kube/config"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    # kubectl provider = raw YAML apply without cluster-scope CRD listing.
    # Required for OpenShift resources (ImageStream, BuildConfig, Route)
    # because hashicorp/kubernetes_manifest demands cluster-scope CRD list
    # permission, which a project-scoped user doesn't have.
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}
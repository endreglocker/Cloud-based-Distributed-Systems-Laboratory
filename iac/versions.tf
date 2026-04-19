terraform {
  required_version = ">= 1.6.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }

  # Távoli state-et is használhatsz (pl. S3, GCS, vagy egy OKD ConfigMap-based
  # backend), most a git-ignorált helyi state marad az egyszerűség kedvéért.
  # backend "kubernetes" {
  #   secret_suffix = "tfstate"
  #   namespace     = "endre-cloud-based-distributed-systems-laboratory"
  # }
}
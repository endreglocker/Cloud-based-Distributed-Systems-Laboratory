terraform {
  required_version = ">= 1.6.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    # kubectl provider = raw YAML apply CRD-listázási jog nélkül.
    # Az OpenShift-specifikus resource-oknak (ImageStream, BuildConfig, Route)
    # erre van szüksége, mert a hashicorp/kubernetes_manifest cluster-scope
    # CRD olvasási jogot követel, amit a projekt-szintű user nem kap meg.
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }

  # Távoli state-et is használhatsz (pl. S3, GCS, vagy egy OKD ConfigMap-based
  # backend), most a git-ignorált helyi state marad az egyszerűség kedvéért.
  # backend "kubernetes" {
  #   secret_suffix = "tfstate"
  #   namespace     = "endre-cloud-based-distributed-systems-laboratory"
  # }
}
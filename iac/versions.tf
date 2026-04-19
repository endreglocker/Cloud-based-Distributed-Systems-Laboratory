terraform {
  required_version = ">= 1.6.0"

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
    # kubectl provider = raw YAML apply CRD-listázási jog nélkül.
    # Az OpenShift-specifikus resource-oknak (ImageStream, BuildConfig, Route)
    # erre van szüksége, mert a hashicorp/kubernetes_manifest cluster-scope
    # CRD olvasási jogot követel, amit a projekt-szintű user nem kap meg.
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}
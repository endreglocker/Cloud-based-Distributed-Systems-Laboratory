# Terraform uses the local ~/.kube/config, or in GitHub Actions the KUBECONFIG
# env variable. Both local runs (after `oc login`) and CI work with the same
# configuration.
provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}

# OpenShift CRDs (Route, BuildConfig, ImageStream)  YAML apply without CRD lookup.
provider "kubectl" {
  config_path      = var.kubeconfig_path
  config_context   = var.kubeconfig_context
  load_config_file = true
}
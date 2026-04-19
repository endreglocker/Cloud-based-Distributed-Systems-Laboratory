# A Terraform a helyi ~/.kube/config-ot használja, vagy GitHub Actions-ben
# a KUBECONFIG env változót. Így működik az `oc login` utáni futtatás és
# a CI/CD is ugyanazzal a konfigurációval.
provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}
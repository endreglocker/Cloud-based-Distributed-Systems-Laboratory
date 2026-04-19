# OpenShift Route with TLS edge termination.
# The IaC equivalent of the manual command:
#   oc patch route my-app -p '{"spec":{"tls":{"termination":"edge"}}}'
resource "kubectl_manifest" "route" {
  yaml_body = yamlencode({
    apiVersion = "route.openshift.io/v1"
    kind       = "Route"
    metadata = {
      name      = var.app_name
      namespace = var.namespace
      labels = {
        "app.kubernetes.io/name"       = var.app_name
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }
    spec = {
      host = var.app_host
      to = {
        kind   = "Service"
        name   = kubernetes_service.app.metadata[0].name
        weight = 100
      }
      port = {
        targetPort = "http"
      }
      tls = {
        termination                   = "edge"
        insecureEdgeTerminationPolicy = "Redirect"
      }
      wildcardPolicy = "None"
    }
  })
}
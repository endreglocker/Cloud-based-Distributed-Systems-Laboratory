# OpenShift Route — TLS edge terminálással. A manuálisan futtatott
# `oc patch route my-app -p '{"spec":{"tls":{"termination":"edge"}}}'`
# megfelelője, IaC formában.
resource "kubernetes_manifest" "route" {
  manifest = {
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
  }
}
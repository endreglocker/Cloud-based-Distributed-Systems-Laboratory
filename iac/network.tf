# Same NetworkPolicy as in the earlier V1–V4 docs: allow all ingress.
# A stricter environment would only allow traffic from the router pods,
# but keeping parity with the previous manual workflow for now.
resource "kubernetes_network_policy" "allow_all_ingress" {
  metadata {
    name      = "allow-all-ingress"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]

    ingress {
      # empty block = allow from any source
    }
  }
}
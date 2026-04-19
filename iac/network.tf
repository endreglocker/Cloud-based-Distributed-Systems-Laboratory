# Ugyanaz a NetworkPolicy, ami a docsban is szerepel: minden ingress engedélyezve.
# Szigorúbb környezetben érdemes csak a router podokat engedni, most maradjunk
# a meglévő viselkedésnél.
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
      # üres blokk = minden forrás
    }
  }
}
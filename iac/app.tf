# A feltöltött képekhez tartozó PVC — szintén védett, hogy redeploynál
# ne veszítsünk el képet.
resource "kubernetes_persistent_volume_claim" "media" {
  metadata {
    name      = "${var.app_name}-media"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"       = var.app_name
      "app.kubernetes.io/component"  = "media"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.media_storage_size
      }
    }
  }

  wait_until_bound = false

  lifecycle {
    prevent_destroy = true
  }
}

# A belső OpenShift image registry címe, hogy a Deployment az ImageStreamből
# húzza az image-et.
locals {
  internal_image = "image-registry.openshift-image-registry.svc:5000/${var.namespace}/${var.app_name}:latest"
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"       = var.app_name
      "app.kubernetes.io/component"  = "web"
      "app.kubernetes.io/managed-by" = "terraform"
    }
    # Ez az annotation kérleli az OpenShiftet, hogy az ImageStream :latest tag
    # változásakor automatikusan tekerje újra a Deploymentet. Így a BuildConfig
    # lefutása után frissül az alkalmazás Terraform-apply nélkül is.
    annotations = {
      "image.openshift.io/triggers" = jsonencode([
        {
          from = {
            kind      = "ImageStreamTag"
            name      = "${var.app_name}:latest"
            namespace = var.namespace
          }
          fieldPath = "spec.template.spec.containers[?(@.name==\"${var.app_name}\")].image"
        }
      ])
    }
  }

  spec {
    replicas = var.app_replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name" = var.app_name
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"      = var.app_name
          "app.kubernetes.io/component" = "web"
        }
      }

      spec {
        container {
          name  = var.app_name
          image = local.internal_image

          port {
            container_port = var.app_port
            name           = "http"
          }

          # Csak a DATABASE_URL-t injektáljuk a db Secretből — az app
          # ennyit lát a DB-ből.
          env {
            name = "DATABASE_URL"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.database.metadata[0].name
                key  = "DATABASE_URL"
              }
            }
          }

          volume_mount {
            name       = "media"
            mount_path = "/app/media"
          }

          readiness_probe {
            http_get {
              path = "/"
              port = var.app_port
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          liveness_probe {
            http_get {
              path = "/"
              port = var.app_port
            }
            initial_delay_seconds = 30
            period_seconds        = 30
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }

        volume {
          name = "media"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.media.metadata[0].name
          }
        }
      }
    }
  }

  # Az OpenShift image trigger a `spec.template.spec.containers[*].image`
  # mezőt a saját kezébe veszi az első deploy után — Terraform ne próbálja
  # visszaírni a :latest tagre minden applynál.
  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].image,
    ]
  }

  depends_on = [
    kubectl_manifest.imagestream,
    kubernetes_secret.database,
  ]
}

resource "kubernetes_service" "app" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"       = var.app_name
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = var.app_name
    }

    port {
      name        = "http"
      port        = var.app_port
      target_port = var.app_port
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}
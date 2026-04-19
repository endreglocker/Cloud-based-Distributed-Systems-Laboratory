# Database PersistentVolumeClaim
# prevent_destroy = true: terraform destroy will NOT delete this;
# removing it requires a manual `terraform state rm` first.
# This satisfies the project requirement that the old database must
# not be wiped on redeploys.
resource "kubernetes_persistent_volume_claim" "postgres" {
  metadata {
    name      = "postgresql-data"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "postgresql"
      "app.kubernetes.io/component"  = "database"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.postgres_storage_size
      }
    }
  }

  wait_until_bound = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgresql"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "postgresql"
      "app.kubernetes.io/component"  = "database"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    replicas = 1

    # Recreate strategy is required because the PVC is ReadWriteOnce 
    # two pods can't mount the volume simultaneously, so a rolling
    # update would deadlock.
    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "postgresql"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"      = "postgresql"
          "app.kubernetes.io/component" = "database"
        }
      }

      spec {
        container {
          name  = "postgresql"
          image = var.postgres_image

          port {
            container_port = 5432
            name           = "postgresql"
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.database.metadata[0].name
            }
          }

          # The sclorg PostgreSQL image writes its data under
          # /var/lib/pgsql/data; that's where the PVC is mounted.
          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/pgsql/data"
          }

          readiness_probe {
            exec {
              command = [
                "/usr/libexec/check-container",
              ]
            }
            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 5
          }

          liveness_probe {
            exec {
              command = [
                "/usr/libexec/check-container",
                "--live",
              ]
            }
            initial_delay_seconds = 120
            period_seconds        = 30
            timeout_seconds       = 10
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }

        volume {
          name = "postgres-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres.metadata[0].name
          }
        }
      }
    }
  }

  # If the DB image tag is a moving "latest", don't show a plan diff on
  # every apply just because the underlying container digest shifted.
  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].image,
    ]
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgresql"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "postgresql"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "postgresql"
    }

    port {
      name        = "postgresql"
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}
# Database credentials.
resource "kubernetes_secret" "database" {
  metadata {
    name      = "${var.app_name}-db"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"       = var.app_name
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  type = "Opaque"

  data = {
    POSTGRESQL_USER     = var.postgres_user
    POSTGRESQL_PASSWORD = var.postgres_password
    POSTGRESQL_DATABASE = var.postgres_database
    # The Django app reads this pre-assembled URL.
    DATABASE_URL = "postgres://${var.postgres_user}:${var.postgres_password}@postgresql:5432/${var.postgres_database}"
  }
}
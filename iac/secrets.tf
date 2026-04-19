# GitHub clone hitelesítés a BuildConfighoz (ugyanaz, mint a manuális
# `oc create secret generic git-secret --type=kubernetes.io/basic-auth`).
resource "kubernetes_secret" "git" {
  metadata {
    name      = "git-secret"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"       = var.app_name
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  type = "kubernetes.io/basic-auth"

  data = {
    username = var.github_username
    password = var.github_token
  }
}

# Adatbázis-hitelesítés. Külön Secret, hogy egy helyen legyen az igazság,
# és a DATABASE_URL ebből álljon össze az appban és a PostgreSQL-ben is.
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
    # A Django app ezt az összefűzött URL-t olvassa.
    DATABASE_URL = "postgres://${var.postgres_user}:${var.postgres_password}@postgresql:5432/${var.postgres_database}"
  }

  # A jelszó változtatása a Secret-et frissíti, de a futó PostgreSQL-ben
  # a pg_authid-ben tárolt hash-t NEM cseréli le. Jelszócserét kézzel
  # kell végigvinni a DB-ben is (pl. ALTER USER ...). A lifecycle blokk
  # nem véd ez ellen — ez csak figyelmeztetés.
}
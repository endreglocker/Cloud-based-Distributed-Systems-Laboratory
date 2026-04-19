# ImageStream — az OpenShift belső image registry címkéje, amire a Deployment
# mutat. A BuildConfig ide pusholja az új image-eket.
resource "kubectl_manifest" "imagestream" {
  yaml_body = yamlencode({
    apiVersion = "image.openshift.io/v1"
    kind       = "ImageStream"
    metadata = {
      name      = var.app_name
      namespace = var.namespace
      labels = {
        "app.kubernetes.io/name"       = var.app_name
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }
    spec = {
      lookupPolicy = {
        local = false
      }
    }
  })
}

# BuildConfig — klónoz a GitHubról a git-secret-tel, Dockerfile-lel buildel,
# és az ImageStream :latest tagjére pusholja az eredményt.
resource "kubectl_manifest" "buildconfig" {
  yaml_body = yamlencode({
    apiVersion = "build.openshift.io/v1"
    kind       = "BuildConfig"
    metadata = {
      name      = var.app_name
      namespace = var.namespace
      labels = {
        "app.kubernetes.io/name"       = var.app_name
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }
    spec = {
      source = {
        type = "Git"
        git = {
          uri = var.git_repo_url
          ref = var.git_branch
        }
        # Publikus repo — nem kell sourceSecret.
      }
      strategy = {
        type           = "Docker"
        dockerStrategy = {}
      }
      output = {
        to = {
          kind = "ImageStreamTag"
          name = "${var.app_name}:latest"
        }
      }
      triggers = [
        { type = "ConfigChange" },
      ]
    }
  })

  depends_on = [kubectl_manifest.imagestream]
}
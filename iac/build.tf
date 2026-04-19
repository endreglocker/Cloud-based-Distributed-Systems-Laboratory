# ImageStream, a named tag inside OpenShift's internal image registry.
# The BuildConfig pushes new images to this tag; the Deployment references it.
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

# BuildConfig, clones the public GitHub repo, builds via Dockerfile,
# pushes the result to the ImageStream's :latest tag.
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
        # Public repo, no sourceSecret needed.
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
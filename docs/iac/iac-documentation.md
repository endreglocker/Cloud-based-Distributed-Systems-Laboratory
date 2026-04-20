# IaC Deployment Documentation

## Project: Cloud-based Distributed Systems Laboratory

**Namespace:** `endre-cloud-based-distributed-systems-laboratory`

**Public URL:** https://my-app-endre-cloud-based-distributed-systems-laboratory.apps.okd.fured.cloud.bme.hu

## Tool Selection

**HashiCorp Terraform** was chosen over platform-native options (e.g. raw OpenShift templates, Helm, Kustomize) for three reasons:

1. **Platform-neutral.**
2. **Lifecycle guarantees.** The `lifecycle { prevent_destroy = true }` block gives a second, explicit layer of protection on stateful resources (the PostgreSQL and media PVCs). Even a `terraform destroy` command is refused until the resource is removed from state manually.

# Terraform IaC Bundle for the Photo Album on OKD

This bundle contains the declarative definitions (Terraform) for the Django photo album application, the PostgreSQL database, and every associated OpenShift resource (BuildConfig, ImageStream, Route, NetworkPolicy, Secret, PVC). The directory lives at `iac/` in the repository root.

## Directory structure

Terraform files:

```
iac/
├── versions.tf               # Terraform + provider versions + remote state backend
├── providers.tf              # Kubernetes + kubectl provider wiring
├── variables.tf              # All input variables
├── secrets.tf                # Database Secret
├── database.tf               # PostgreSQL: Deployment + Service + PVC
├── build.tf                  # ImageStream + BuildConfig
├── app.tf                    # Django app: Deployment + Service + media PVC
├── route.tf                  # OpenShift Route with TLS edge termination
├── network.tf                # NetworkPolicy (router ingress)
└── outputs.tf                # Route URL and helper outputs
```

CI/CD:

```
.github/workflows/deploy.yml
```

## `iac/versions.tf` - Terraform contract & remote state

Terraform core version, declares which providers are needed and configures the **remote state backend**.

`hashicorp/kubernetes` handles every standard Kubernetes resource (Deployment, Service, Secret, PVC, NetworkPolicy)

Without the `backend "kubernetes"` block, Terraform stores state in a local `terraform.tfstate` file. That works for local development but breaks completely in CI: every GitHub Actions run starts on a fresh runner with no files, so Terraform thinks the cluster is empty and tries to recreate everything, colliding with resources the previous run already made. The `kubernetes` backend stores state as a Secret (`tfstate-default-tfstate`) inside the same namespace the infrastructure is deployed to, which makes state survive across runs and also gives Terraform built-in locking so two simultaneous runs can't corrupt each other.

```hcl
terraform {
  required_version = ">= 1.6.0"

  backend "kubernetes" {
    secret_suffix = "tfstate"
    namespace     = "endre-cloud-based-distributed-systems-laboratory"
    config_path   = "~/.kube/config"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    # kubectl provider = raw YAML apply without cluster-scope CRD listing.
    # Required for OpenShift resources (ImageStream, BuildConfig, Route)
    # because hashicorp/kubernetes_manifest demands CRD list permission
    # at cluster scope, which a project-scoped user doesn't have.
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}
```


## `iac/providers.tf` - Provider configuration

Wires both providers to the same kubeconfig. Locally that's `~/.kube/config` after `oc login`; in GitHub Actions the workflow's login step writes to the same path.

```hcl
# path after `oc login` writes to it. Both local and CI work the same way.
provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}

# OpenShift CRDs (Route, BuildConfig, ImageStream), YAML apply without
# CRD lookup.
provider "kubectl" {
  config_path      = var.kubeconfig_path
  config_context   = var.kubeconfig_context
  load_config_file = true
}
```

## `iac/variables.tf`, Input surface

Defines every value that might need to change between environments or over time, e.g.: public hostname, PostgreSQL credentials, replica count, container port. Default values are also provided.

Variables marked `sensitive = true` are redacted from plan and apply output. Right now that's just `postgres_password`.

## `iac/secrets.tf`, Database credentials

Sets up database secrets

```hcl
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
    DATABASE_URL = "postgres://${var.postgres_user}:${var.postgres_password}@postgresql:5432/${var.postgres_database}"
  }
}
```

## `iac/database.tf` - PostgreSQL

Three resources that together form the database tier:

1. **`postgresql-data` PVC**, 1 Gi ReadWriteOnce volume, with `lifecycle { prevent_destroy = true }`. This is the single location where PostgreSQL data lives. The `prevent_destroy` flag is what turns "careful Terraform usage" into a hard guarantee that the database can't be wiped by an accidental `terraform destroy`.
2. **`postgresql` Deployment**, single replica with `Recreate` strategy (RWO volumes can't be mounted by two pods at once, so a rolling update would deadlock). Uses `quay.io/sclorg/postgresql-15-c9s`, which is OpenShift-friendly regarding random UIDs. Mounts the PVC at `/var/lib/pgsql/data` (where the SCL image writes its data), consumes credentials via `envFrom` from the database Secret, and uses the image's built-in `check-container` script for both liveness and readiness probes. Resource limits are conservative (500m CPU / 512Mi RAM), enough for the course workload.
3. **`postgresql` Service**, ClusterIP on port 5432. The Django app's `DATABASE_URL` resolves to this via Kubernetes DNS.

## `iac/build.tf` - Image pipeline

Two `kubectl_manifest` resources that own the OpenShift build pipeline:

1. **`my-app` ImageStream**, a named tag inside OpenShift's internal image registry. Means pods reference the image by `my-app:latest`.
2. **`my-app` BuildConfig**, declares how to produce new images. Points at the public GitHub repo on branch `main`, uses the Docker strategy (finds the `Dockerfile` at the repo root), and outputs to `my-app:latest` in the ImageStream. Builds are triggered on every code push by the GitHub Actions workflow.


```hcl
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
```

## `iac/app.tf` - Django application tier

1. **`my-app-media` PVC**, 5 Gi volume for user-uploaded images, also `prevent_destroy`. Lives separately from the database PVC so both stateful components have independent lifecycles.
2. **`my-app` Deployment**, N replicas (default 1), `RollingUpdate` strategy. Several subtle pieces come together here:
   - The container `image` is set to the fully-qualified internal registry path (`image-registry.openshift-image-registry.svc:5000/<ns>/my-app:latest`).
   - The `image.openshift.io/triggers` annotation tells OpenShift to rewrite that field to the concrete image digest whenever the ImageStream's `:latest` tag moves. This is what makes "new build --> rolling update" work without any Terraform apply.
   - `lifecycle { ignore_changes = [container.image] }` on the Terraform side means Terraform respects OpenShift's rewrite and doesn't fight it on subsequent applies. Without this, every apply would try to reset the image back to `:latest`, conflicting with whatever digest OpenShift had just rolled out.
   - `DATABASE_URL` is injected via `secret_key_ref`, the Django app sees only the URL it needs, not the full set of credentials.
   - The media PVC is mounted at `/app/media`, matching `MEDIA_ROOT` in the Django settings.
   - HTTP liveness and readiness probes on `/` ensure the Deployment only considers a pod ready once Django is actually serving.
3. **`my-app` Service**, ClusterIP on port 8000, named `http` so the Route can reference it symbolically.

## `iac/route.tf` -  Public HTTPS endpoint

A single `kubectl_manifest` creating the OpenShift Route.

- **Edge TLS termination**, the cluster router terminates HTTPS with a wildcard certificate covering `*.apps.okd.fured.cloud.bme.hu`; traffic from the router to the pod is plain HTTP. This avoids shipping certificates into the app container.
- **`insecureEdgeTerminationPolicy: Redirect`**, any request to `http://...` gets a 302 to `https://...`, so users who type the hostname without a scheme still end up on HTTPS.


## `iac/network.tf`

Creates a single `NetworkPolicy` allowing all ingress traffic to all pods in the namespace. 

```hcl
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
      
    }
  }
}
```

## `iac/outputs.tf`

Prints the Route URL, namespace, internal DB connection string, and the first-time `oc start-build` command after `terraform apply`. 

```hcl
output "route_url" {
  description = "Public HTTPS URL of the photo album"
  value       = "https://${var.app_host}"
}

output "namespace" {
  description = "OKD project namespace"
  value       = var.namespace
}

output "database_service" {
  description = "Internal DNS name of the PostgreSQL service"
  value       = "${kubernetes_service.postgres.metadata[0].name}.${var.namespace}.svc.cluster.local:5432"
}

output "build_command" {
  description = "Run this after `terraform apply` to produce the first app image"
  value       = "oc start-build ${var.app_name} -n ${var.namespace} --follow"
}
```

## `.github/workflows/deploy.yml`, CI/CD orchestration

Ties every code push to the full deployment pipeline. Three jobs:

- **`test`** runs on push and PR; installs Python deps, runs Django's system check and unit tests against an in-memory SQLite. Nothing in the cluster is touched at this stage.
- **`infra`** runs only on push to `main` after `test` passes. Logs into OKD with `OKD_TOKEN`, runs `terraform init` (which downloads both providers and pulls state from the namespace Secret), `terraform plan`, and `terraform apply`.
- **`build`** runs only on push to `main` after `infra` passes. Triggers a new OpenShift build via the cluster API.

```yaml
name: CI/CD

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    name: Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.13'

      - name: Install dependencies
        working-directory: image_viewer
        run: pip install -r requirements.txt

      - name: Django system check
        working-directory: image_viewer
        env:
          DATABASE_URL: sqlite:///tmp/test.db
        run: python manage.py check

      - name: Run tests
        working-directory: image_viewer
        env:
          DATABASE_URL: sqlite:///tmp/test.db
        run: python manage.py test

  infra:
    name: Terraform apply (IaC)
    needs: test
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: iac
    steps:
      - uses: actions/checkout@v4

      - name: Install OC CLI
        run: |
          curl -fsSL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz \
            | sudo tar -xz -C /usr/local/bin oc kubectl
          oc version --client

      - name: Login to OKD
        run: |
          oc login https://api.okd.fured.cloud.bme.hu:6443 \
            --token="${{ secrets.OKD_TOKEN }}" \
            --insecure-skip-tls-verify=true
          oc project endre-cloud-based-distributed-systems-laboratory

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.8

      - name: Terraform init
        run: terraform init -input=false

      - name: Terraform validate
        run: terraform validate

      - name: Terraform plan
        env:
          TF_VAR_postgres_password: ${{ secrets.POSTGRES_PASSWORD }}
        run: terraform plan -input=false -out=tfplan

      - name: Terraform apply
        env:
          TF_VAR_postgres_password: ${{ secrets.POSTGRES_PASSWORD }}
        run: terraform apply -input=false -auto-approve tfplan

  build:
    name: Build & deploy image
    needs: infra
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Trigger OpenShift build
        run: |
          curl -k -X POST \
            -H "Authorization: Bearer ${{ secrets.OKD_TOKEN }}" \
            -H "Content-Type: application/json" \
            https://api.okd.fured.cloud.bme.hu:6443/apis/build.openshift.io/v1/namespaces/endre-cloud-based-distributed-systems-laboratory/buildconfigs/my-app/instantiate \
            -d '{"kind":"BuildRequest","apiVersion":"build.openshift.io/v1","metadata":{"name":"my-app"}}'
```

### Required GitHub Secrets

| Secret name |
|---|---|
| `OKD_TOKEN` |
| `POSTGRES_PASSWORD` |


## Components configured

| Layer | Resource | Note |
|---|---|---|
| Access | `Secret/my-app-db` | DB user/password/database + DATABASE_URL |
| Network | `NetworkPolicy/allow-all-ingress` | Allows router traffic |
| Network | `Service/postgresql`, `Service/my-app` | Internal ClusterIP |
| Network | `Route/my-app` | Public HTTPS, TLS edge, HTTP-->HTTPS redirect |
| Storage | `PVC/postgresql-data` | 1Gi, `prevent_destroy=true` |
| Storage | `PVC/my-app-media` | 5Gi, `prevent_destroy=true` |
| Build | `ImageStream/my-app` | Internal registry tag |
| Build | `BuildConfig/my-app` | Docker strategy, pushes :latest |
| Runtime | `Deployment/postgresql` | 1 replica, Recreate strategy |
| Runtime | `Deployment/my-app` | N replicas, RollingUpdate, ImageStream trigger |

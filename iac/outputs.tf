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
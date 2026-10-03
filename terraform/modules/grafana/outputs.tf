output "workspace_id" {
  value = var.create ? aws_grafana_workspace.this[0].id : null
}

output "endpoint" {
  value = var.create ? aws_grafana_workspace.this[0].endpoint : null
}

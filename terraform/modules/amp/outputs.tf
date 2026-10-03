output "workspace_id" {
  value = aws_prometheus_workspace.this.id
}

output "workspace_arn" {
  value = aws_prometheus_workspace.this.arn
}

output "remote_write_endpoint" {
  description = "Prometheus remote_write URL for anything that will send metrics here (e.g. an ADOT sidecar — see README.md)."
  value       = "${aws_prometheus_workspace.this.prometheus_endpoint}api/v1/remote_write"
}

output "query_endpoint" {
  value = aws_prometheus_workspace.this.prometheus_endpoint
}

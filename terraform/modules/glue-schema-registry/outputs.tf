output "registry_name" {
  value = aws_glue_registry.this.registry_name
}

output "registry_arn" {
  value = aws_glue_registry.this.arn
}

output "vpc_endpoint_id" {
  value = var.create_vpc_endpoint ? aws_vpc_endpoint.glue[0].id : null
}

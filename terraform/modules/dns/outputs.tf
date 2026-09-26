output "zone_id" {
  description = "Route 53 zone ID in use (newly created or existing, per create_zone)."
  value       = var.create_zone ? aws_route53_zone.this[0].zone_id : var.existing_zone_id
}

output "name_servers" {
  description = "Name servers for the zone, if this module created it. Delegate the domain at your registrar to these. Empty list when reusing an existing zone."
  value       = var.create_zone ? aws_route53_zone.this[0].name_servers : []
}

output "domain_name" {
  description = "Domain name this zone serves."
  value       = var.domain_name
}

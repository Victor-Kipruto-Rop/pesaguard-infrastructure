output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_arn_suffix" {
  description = "Short form used as a CloudWatch metric dimension (e.g. app/my-alb/50dc6c495c0c9188), not the full ARN."
  value       = aws_lb.this.arn_suffix
}

output "alb_zone_id" {
  description = "The ALB's own hosted zone ID, for creating a Route 53 ALIAS record to it."
  value       = aws_lb.this.zone_id
}

output "https_enabled" {
  value = local.enable_https
}

output "primary_listener_arn" {
  description = "The HTTPS listener's ARN if a certificate was provided, otherwise the HTTP listener's ARN. This is the listener application services (Phase 9) should attach listener rules to."
  value       = local.enable_https ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
}

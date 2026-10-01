output "certificate_arn" {
  description = "Validated certificate ARN — use aws_acm_certificate_validation's ARN, not the raw certificate, so consumers wait on validation."
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "domain_name" {
  value = var.domain_name
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider in use (created here or passed in via existing_oidc_provider_arn)."
  value       = local.oidc_provider_arn
}

output "terraform_ci_role_arn" {
  description = "Role GitHub Actions assumes via OIDC to run terraform plan/apply."
  value       = aws_iam_role.terraform_ci.arn
}

output "app_service_role_arn" {
  value = aws_iam_role.app_service.arn
}

output "app_service_role_name" {
  value = aws_iam_role.app_service.name
}

output "app_service_instance_profile_name" {
  value = aws_iam_instance_profile.app_service.name
}

output "monitoring_role_arn" {
  value = aws_iam_role.monitoring.arn
}

output "monitoring_instance_profile_name" {
  value = aws_iam_instance_profile.monitoring.name
}

output "backup_operator_role_arn" {
  value = aws_iam_role.backup_operator.arn
}

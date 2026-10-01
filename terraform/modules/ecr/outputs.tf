output "repository_urls" {
  description = "Map of repository name (as given in var.repository_names) => full repository URL, for use as an image build/push target."
  value       = { for name, r in aws_ecr_repository.this : name => r.repository_url }
}

output "repository_arns" {
  value = { for name, r in aws_ecr_repository.this : name => r.arn }
}

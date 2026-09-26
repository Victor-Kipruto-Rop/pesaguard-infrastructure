output "state_bucket_name" {
  description = "Name of the S3 bucket holding Terraform state for this environment."
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  description = "ARN of the state bucket."
  value       = aws_s3_bucket.state.arn
}

output "lock_table_name" {
  description = "Name of the DynamoDB table used for state locking."
  value       = aws_dynamodb_table.lock.name
}

output "lock_table_arn" {
  description = "ARN of the lock table."
  value       = aws_dynamodb_table.lock.arn
}

output "backend_hcl" {
  description = "Ready-to-use backend config block for this environment's backend.hcl."
  value       = <<-EOT
    bucket         = "${aws_s3_bucket.state.id}"
    key            = "environments/${var.environment}/terraform.tfstate"
    region         = "${var.region}"
    dynamodb_table = "${aws_dynamodb_table.lock.name}"
    encrypt        = true
  EOT
}

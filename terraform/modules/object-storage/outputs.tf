output "bucket_arns" {
  description = "Map of bucket name (as given in var.buckets) => ARN."
  value       = { for name, b in aws_s3_bucket.this : name => b.arn }
}

output "bucket_names" {
  description = "Map of bucket name (as given in var.buckets) => actual S3 bucket name."
  value       = { for name, b in aws_s3_bucket.this : name => b.id }
}

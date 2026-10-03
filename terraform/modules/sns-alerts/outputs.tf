output "topic_arns" {
  description = "Map of category (as given in var.topics) => SNS topic ARN."
  value       = { for name, t in aws_sns_topic.this : name => t.arn }
}

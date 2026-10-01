output "cluster_id" {
  value = aws_ecs_cluster.this.id
}

output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "execution_role_arn" {
  value = aws_iam_role.execution.arn
}

output "service_names" {
  value = keys(var.services)
}

output "target_group_arns" {
  value = { for k, tg in aws_lb_target_group.service : k => tg.arn }
}

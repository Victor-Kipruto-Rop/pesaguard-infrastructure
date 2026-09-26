output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "availability_zones" {
  description = "Availability zones this VPC is spread across, in subnet-array order."
  value       = var.availability_zones
}

output "public_subnet_ids" {
  description = "Public subnet IDs (ALB, NAT gateways)."
  value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "Application-tier private subnet IDs (FastAPI, Java services, workers)."
  value       = aws_subnet.app[*].id
}

output "data_subnet_ids" {
  description = "Data-tier private subnet IDs (RDS, Redis, Kafka) — no internet route."
  value       = aws_subnet.data[*].id
}

output "nat_gateway_ids" {
  description = "NAT gateway IDs."
  value       = aws_nat_gateway.this[*].id
}

output "internet_gateway_id" {
  description = "Internet gateway ID."
  value       = aws_internet_gateway.this.id
}

output "public_route_table_id" {
  description = "Public route table ID."
  value       = aws_route_table.public.id
}

output "app_route_table_ids" {
  description = "App-tier route table IDs (one per AZ)."
  value       = aws_route_table.app[*].id
}

output "data_route_table_id" {
  description = "Data-tier route table ID (no internet route)."
  value       = aws_route_table.data.id
}

output "flow_log_group_name" {
  description = "CloudWatch Logs group name for VPC flow logs, if enabled."
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : null
}

output "db_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "db_address" {
  description = "RDS PostgreSQL address (without port)"
  value       = aws_db_instance.postgres.address
}

output "db_port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.postgres.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.postgres.db_name
}

output "db_username" {
  description = "Database username"
  value       = var.db_username
  sensitive   = true
}

output "security_group_id" {
  description = "Security group ID for the RDS instance"
  value       = aws_security_group.rds_sg.id
}

output "vpc_id" {
  description = "VPC ID where the database is located"
  value       = data.aws_vpc.default.id
}

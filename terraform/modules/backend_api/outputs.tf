output "backend_public_ip" {
  description = "Public IP of the backend EC2 instance"
  value       = aws_instance.backend.public_ip
}

output "backend_url" {
  description = "Backend API URL"
  value       = "http://${aws_instance.backend.public_ip}:3000"
}

output "backend_instance_id" {
  description = "Instance ID of the backend EC2"
  value       = aws_instance.backend.id
}

output "security_group_id" {
  description = "Security group ID for the backend EC2"
  value       = var.security_group_id
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group name for backend logs"
  value       = aws_cloudwatch_log_group.backend_logs.name
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch Log Group ARN for backend logs"
  value       = aws_cloudwatch_log_group.backend_logs.arn
}

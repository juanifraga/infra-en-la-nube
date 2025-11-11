output "public_ip" {
  value = module.web_ec2.public_ip
}

output "web_url" {
  value = "http://${module.web_ec2.public_ip}"
}

output "bucket_name" {
  value       = aws_s3_bucket.md_source.bucket
  description = "Name of the S3 bucket for articles"
}

output "bucket_arn" {
  value       = aws_s3_bucket.md_source.arn
  description = "ARN of the S3 bucket"
}

output "lambda_name" {
  value       = module.lambda_generator.lambda_name
  description = "Name of the Lambda function"
}

output "lambda_arn" {
  value       = module.lambda_generator.lambda_arn
  description = "ARN of the Lambda function"
}

output "alb_dns_name" {
  value       = aws_lb.backend.dns_name
  description = "DNS name of the Application Load Balancer"
}

output "backend_url" {
  value       = "http://${aws_lb.backend.dns_name}"
  description = "Backend API URL (via Load Balancer)"
}

output "backend_instance_ips" {
  value       = [for instance in module.backend_api : instance.backend_public_ip]
  description = "Public IPs of all backend EC2 instances"
}

output "backend_instance_ids" {
  value       = [for instance in module.backend_api : instance.backend_instance_id]
  description = "Instance IDs of all backend EC2 instances"
}

output "db_endpoint" {
  value       = module.comments_db.db_endpoint
  description = "RDS PostgreSQL endpoint"
  sensitive   = true
}

output "db_name" {
  value       = module.comments_db.db_name
  description = "Database name"
}
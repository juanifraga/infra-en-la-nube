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

output "backend_url" {
  value       = module.backend_api.backend_url
  description = "Backend API URL"
}

output "backend_public_ip" {
  value       = module.backend_api.backend_public_ip
  description = "Public IP of the backend EC2 instance"
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
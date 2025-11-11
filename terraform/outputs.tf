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
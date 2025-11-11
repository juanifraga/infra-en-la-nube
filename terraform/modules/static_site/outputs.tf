output "website_url" {
  description = "URL de CloudFront para acceder al sitio estático"
  value       = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
}

output "s3_bucket_id" {
  description = "ID del bucket S3 creado"
  value       = aws_s3_bucket.site_bucket.id
}
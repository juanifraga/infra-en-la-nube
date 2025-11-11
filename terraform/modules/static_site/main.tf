# S3 Bucket 
resource "aws_s3_bucket" "site_bucket" {
  bucket = var.bucket_name
  tags   = var.tags
  force_destroy = true 
}

# Bloquear todo acceso público directo al bucket
resource "aws_s3_bucket_public_access_block" "site_bucket_block" {
  bucket = aws_s3_bucket.site_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Origin Access Control (OAC)
resource "aws_cloudfront_origin_access_control" "site_oac" {
  name                              = "${var.bucket_name}-oac"
  description                       = "OAC para sitio estatico ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100" # Usa solo nodos de NA y Europa (más barato para pruebas)

  origin {
    domain_name              = aws_s3_bucket.site_bucket.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.site_bucket.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.site_oac.id
  }

  # Configuración del Cache
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.site_bucket.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600  # 1 hora por defecto
    max_ttl                = 86400 # 24 horas máximo
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = var.tags
}

#S3 Bucket Policy
# Permite que SOLO esta distribución de CloudFront lea los archivos del bucket
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.site_bucket.id
  policy = data.aws_iam_policy_document.cloudfront_oac_access.json
}

data "aws_iam_policy_document" "cloudfront_oac_access" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.site_bucket.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

#PAgina estatica
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.site_bucket.id
  key          = "index.html"
  content_type = "text/html"
  content      = <<EOF
<!DOCTYPE html>
<html>
<head><title>Sitio Institucional</title></head>
<body>
  <h1>Bienvenido a nuestro sitio institucional</h1>
  <p>Este sitio es servido desde S3 a traves de CloudFront para maxima velocidad.</p>
</body>
</html>
EOF
}
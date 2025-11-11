terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
     random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

##############################
# Módulo: Frontend
##############################

module "web_ec2" {
  source           = "./modules/web_ec2"
  name_prefix      = var.name_prefix
  instance_type    = var.instance_type
  key_name         = var.key_name
  allowed_ssh_cidr = var.allowed_ssh_cidr
  docker_image     = var.docker_image
  tags             = var.tags
}

##############################
# Módulo: Generador de artículos
##############################
module "lambda_generator" {
  source           = "./modules/lambda_generator"
  name             = "article-generator"
  target_bucket    = aws_s3_bucket.md_source.bucket
  interval_minutes = var.lambda_interval
  gemini_api_key   = var.gemini_api_key
}

##############################
# S3 Bucket para artículos
##############################
resource "aws_s3_bucket" "md_source" {
  bucket        = "source-md-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "SourceMarkdownBucket"
  }
}

resource "aws_s3_bucket_public_access_block" "md_source_public_access" {
  bucket = aws_s3_bucket.md_source.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Sufijo aleatorio para evitar nombres duplicados
resource "random_id" "bucket_suffix" {
  byte_length = 4
}
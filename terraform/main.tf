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
# Módulo: Backend Infrastructure
##############################

# Get default VPC for backend resources
data "aws_vpc" "default" {
  default = true
}

# Create security group for backend API (needed by DB module)
resource "aws_security_group" "backend_api_sg" {
  name        = "${var.name_prefix}-backend-api-sg"
  description = "Security group for backend API EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH (limited)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-backend-api-sg"
    Component = "Backend API"
    Tier      = "Application"
    ManagedBy = "Terraform"
  })
}

# Create database module (uses backend SG ID)
module "comments_db" {
  source                     = "./modules/comments_db"
  name_prefix                = var.name_prefix
  db_instance_class          = var.db_instance_class
  db_name                    = var.db_name
  db_username                = var.db_username
  db_password                = var.db_password
  allowed_security_group_id  = aws_security_group.backend_api_sg.id
  tags                       = var.tags
}

# Create backend API EC2 instance (uses DB address and pre-created SG)
module "backend_api" {
  source               = "./modules/backend_api"
  name_prefix          = var.name_prefix
  instance_type        = var.instance_type
  key_name             = var.key_name
  security_group_id    = aws_security_group.backend_api_sg.id
  db_host              = module.comments_db.db_address
  db_port              = module.comments_db.db_port
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
  tags                 = var.tags

  depends_on = [module.comments_db]
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
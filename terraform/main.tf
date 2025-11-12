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

module "cloudfront_frontend" {
  source = "./modules/cloudfront_frontend"

  name_prefix        = var.name_prefix
  backend_alb_domain = aws_lb.backend.dns_name
  tags               = var.tags
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
# Módulo: Docusaurus Auto-Rebuild
##############################
module "docusaurus_rebuild" {
  source = "./modules/docusaurus_rebuild"

  name_prefix                = var.name_prefix
  source_bucket_name         = aws_s3_bucket.md_source.id
  destination_bucket_name    = module.cloudfront_frontend.bucket_name
  cloudfront_distribution_id = module.cloudfront_frontend.cloudfront_distribution_id
  github_repo_url            = var.github_repo_url
  github_branch              = var.github_branch
  tags                       = var.tags
}

##############################
# Módulo: Backend Infrastructure
##############################

# Get default VPC for backend resources
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-alb-sg"
    Component = "Load Balancer"
    Tier      = "Application"
    ManagedBy = "Terraform"
  })
}

# Create security group for backend API (needed by DB module and ALB)
resource "aws_security_group" "backend_api_sg" {
  name        = "${var.name_prefix}-backend-api-sg"
  description = "Security group for backend API EC2 instances"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
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

# Application Load Balancer
resource "aws_lb" "backend" {
  name               = "${var.name_prefix}-backend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-backend-alb"
    Component = "Load Balancer"
    Tier      = "Application"
    ManagedBy = "Terraform"
  })
}

# Target Group for backend instances
resource "aws_lb_target_group" "backend" {
  name     = "${var.name_prefix}-backend-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-backend-tg"
    Component = "Load Balancer"
    Tier      = "Application"
    ManagedBy = "Terraform"
  })
}

# Load Balancer Listener
resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.backend.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  tags = merge(var.tags, {
    Component = "Load Balancer"
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

module "backend_api" {
  source   = "./modules/backend_api"
  count    = var.backend_instance_count

  name_prefix          = var.name_prefix
  instance_name_suffix = "-${count.index + 1}"
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

resource "aws_lb_target_group_attachment" "backend" {
  count            = var.backend_instance_count
  target_group_arn = aws_lb_target_group.backend.arn
  target_id        = module.backend_api[count.index].backend_instance_id
  port             = 3000
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

##############################
# static site module
##############################
module "static_site" {
  source      = "./modules/static_site"
  bucket_name = "static-site-bucket-642878372863"
  tags = {
    Name        = "StaticSiteModule"
  }
}
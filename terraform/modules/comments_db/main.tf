# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Security group for RDS PostgreSQL instance - only accessible within VPC"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "PostgreSQL from backend EC2 only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.allowed_security_group_id]
  }

  # No egress rules needed for RDS - it's managed by AWS
  egress {
    description = "No outbound access needed"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-rds-sg"
    Component = "Database"
    Tier      = "Data"
    ManagedBy = "Terraform"
  })
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-db-subnet-group"
    Component = "Database"
    Tier      = "Data"
    ManagedBy = "Terraform"
  })
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  identifier             = "${var.name_prefix}-postgres"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  storage_type           = "gp3"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  
  # Security settings - NOT publicly accessible
  publicly_accessible = false
  
  # Backup settings (free tier supports 0-1 days)
  backup_retention_period = 1
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"
  
  # Deletion protection for production
  skip_final_snapshot = true
  # deletion_protection = true  # Enable this for production
  
  # Performance insights (optional)
  # performance_insights_enabled = true
  
  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-postgres"
    Component = "Database"
    Tier      = "Data"
    ManagedBy = "Terraform"
    Engine    = "PostgreSQL"
  })
}

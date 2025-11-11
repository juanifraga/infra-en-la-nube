data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

locals {
  user_data = templatefile("${path.module}/user_data.sh", {
    db_host     = var.db_host
    db_port     = var.db_port
    db_name     = var.db_name
    db_user     = var.db_username
    db_password = var.db_password
  })
}

resource "aws_instance" "backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = element(data.aws_subnets.default.ids, 0)
  vpc_security_group_ids = [var.security_group_id]
  
  # Only apply user data if db_host is provided
  user_data = var.db_host != "" ? local.user_data : null

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-backend-ec2"
    Component = "Backend API"
    Tier      = "Application"
    ManagedBy = "Terraform"
    Runtime   = "Node.js"
  })
}

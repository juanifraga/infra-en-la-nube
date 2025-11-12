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
  log_group_name = "/aws/ec2/${var.name_prefix}-backend"
  user_data = templatefile("${path.module}/user_data.sh", {
    db_host        = var.db_host
    db_port        = var.db_port
    db_name        = var.db_name
    db_user        = var.db_username
    db_password    = var.db_password
    log_group_name = local.log_group_name
  })
}

# IAM Role for EC2 to write to CloudWatch Logs
resource "aws_iam_role" "backend_role" {
  name = "${var.name_prefix}-backend-role${var.instance_name_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

# IAM Policy for CloudWatch Logs
resource "aws_iam_policy" "backend_cloudwatch_policy" {
  name        = "${var.name_prefix}-backend-cloudwatch-policy${var.instance_name_suffix}"
  description = "Allow EC2 to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "backend_cloudwatch_attach" {
  role       = aws_iam_role.backend_role.name
  policy_arn = aws_iam_policy.backend_cloudwatch_policy.arn
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "backend_profile" {
  name = "${var.name_prefix}-backend-profile${var.instance_name_suffix}"
  role = aws_iam_role.backend_role.name
}

# CloudWatch Log Group for Backend
resource "aws_cloudwatch_log_group" "backend_logs" {
  name              = "${local.log_group_name}${var.instance_name_suffix}"
  retention_in_days = 7

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-backend-logs${var.instance_name_suffix}"
    Component = "Backend API"
  })
}

resource "aws_instance" "backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = element(data.aws_subnets.default.ids, 0)
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.backend_profile.name

  # Only apply user data if db_host is provided
  user_data = var.db_host != "" ? local.user_data : null

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-backend-ec2${var.instance_name_suffix}"
    Component = "Backend API"
    Tier      = "Application"
    ManagedBy = "Terraform"
    Runtime   = "Node.js"
  })
}

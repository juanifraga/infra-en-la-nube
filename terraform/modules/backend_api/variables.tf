variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "instance_name_suffix" {
  description = "Suffix for instance name (e.g., -1, -2)"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID to attach to the instance"
  type        = string
  default     = ""
}

variable "iam_instance_profile" {
  description = "IAM instance profile name to attach to the instance"
  type        = string
}

variable "cloudwatch_log_group" {
  description = "CloudWatch log group name for logging"
  type        = string
}

variable "aws_region" {
  description = "AWS region for CloudWatch Agent"
  type        = string
}

variable "db_host" {
  description = "Database host address"
  type        = string
  default     = ""
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Allowed CIDR for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}


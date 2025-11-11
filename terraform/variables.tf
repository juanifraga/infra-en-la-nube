variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "name_prefix" {
  type    = string
  default = "docusaurus"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type = string
  # Tu key pair de AWS para SSH
}

variable "allowed_ssh_cidr" {
  type    = string
  default = "YOUR.PUBLIC.IP/32"
  # cámbialo
}

variable "docker_image" {
  type    = string
  default = "juanifraga/infra-en-la-nube:latest"
}

variable "tags" {
  type = map(string)
  default = {
    "Project" = "Obligatorio2"
    "Owner"   = "Juani"
  }
}

variable "lambda_interval" {
  description = "Interval in minutes for the Lambda function to run"
  type        = number
  default     = 2
}

variable "gemini_api_key" {
  description = "Google Gemini API key for generating articles"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class for the backend database"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name for the backend"
  type        = string
  default     = "commentsdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "backend_instance_count" {
  description = "Number of backend EC2 instances to create"
  type        = number
  default     = 2
}
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
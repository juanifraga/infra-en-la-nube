variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "docusaurus"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
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

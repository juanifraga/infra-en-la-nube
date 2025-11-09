variable "name_prefix"      { type = string }
variable "instance_type"    { type = string }
variable "key_name"         { type = string }
variable "allowed_ssh_cidr" { type = string }
variable "docker_image"     { type = string }
variable "tags"             { type = map(string) }
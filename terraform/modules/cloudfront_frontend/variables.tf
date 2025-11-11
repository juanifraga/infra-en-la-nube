variable "name_prefix" {
  type        = string
  description = "Prefix for resource names"
}

variable "backend_alb_domain" {
  type        = string
  description = "Domain name of the backend ALB (without http://)"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}

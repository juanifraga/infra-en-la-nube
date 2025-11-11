variable "bucket_name" {
  description = "Nombre_Bucket_S3"
  type        = string
}

variable "tags" {
  description = "Etiquetas para asignar a los recursos"
  type        = map(string)
  default     = {}
}
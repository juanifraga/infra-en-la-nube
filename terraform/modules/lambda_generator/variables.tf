variable "name" {
  description = "Base name for Lambda and resources"
  type        = string
}

variable "target_bucket" {
  description = "Name of the S3 bucket where Markdown files are uploaded"
  type        = string
}

variable "interval_minutes" {
  description = "Interval in minutes for article generation"
  type        = number
  default     = 2

  validation {
    condition     = var.interval_minutes >= 1
    error_message = "Interval must be at least 1 minute."
  }
}

variable "gemini_api_key" {
  description = "Google Gemini API key for generating articles"
  type        = string
  sensitive   = true
}
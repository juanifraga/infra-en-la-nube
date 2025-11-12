variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "source_bucket_name" {
  description = "S3 bucket containing markdown source files"
  type        = string
}

variable "destination_bucket_name" {
  description = "S3 bucket for Docusaurus frontend"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  type        = string
}

variable "github_repo_url" {
  description = "GitHub repository URL for the Docusaurus project"
  type        = string
  default = "https://github.com/juanifraga/infra-en-la-nube"
}

variable "github_branch" {
  description = "GitHub branch to build from"
  type        = string
  default     = "main"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

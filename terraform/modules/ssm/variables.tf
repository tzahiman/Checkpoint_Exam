variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "api_token" {
  description = "API token value"
  type        = string
  sensitive   = true
}

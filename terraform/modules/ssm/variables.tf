variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "api_auth_value" {
  description = "API auth value (e.g. from random_password); stored in SSM"
  type        = string
  sensitive   = true
}

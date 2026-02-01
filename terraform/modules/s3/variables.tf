variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "iam_user_name" {
  description = "IAM user name to attach the S3 public access policy to"
  type        = string
  default     = "avanan-candidate-2"
}

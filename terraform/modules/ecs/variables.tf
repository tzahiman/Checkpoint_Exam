variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ALB security group ID"
  type        = string
}

variable "target_group_arn" {
  description = "Target group ARN"
  type        = string
}

variable "api_service_cpu" {
  description = "CPU units for API service"
  type        = number
}

variable "api_service_memory" {
  description = "Memory for API service in MB"
  type        = number
}

variable "sqs_consumer_cpu" {
  description = "CPU units for SQS consumer"
  type        = number
}

variable "sqs_consumer_memory" {
  description = "Memory for SQS consumer in MB"
  type        = number
}

variable "api_service_port" {
  description = "API service port"
  type        = number
}

variable "sqs_poll_interval" {
  description = "SQS polling interval in seconds"
  type        = number
}

variable "api_service_desired_count" {
  description = "Desired count for API service"
  type        = number
  default     = 2
}

variable "sqs_consumer_desired_count" {
  description = "Desired count for SQS consumer"
  type        = number
  default     = 1
}

variable "ecr_repository_api" {
  description = "ECR repository URL for API service"
  type        = string
}

variable "ecr_repository_sqs_consumer" {
  description = "ECR repository URL for SQS consumer"
  type        = string
}

variable "sqs_queue_url" {
  description = "SQS queue URL"
  type        = string
}

variable "sqs_queue_arn" {
  description = "SQS queue ARN"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN"
  type        = string
}

variable "ssm_token_parameter_name" {
  description = "SSM parameter name for token"
  type        = string
}

variable "ssm_token_parameter_arn" {
  description = "SSM parameter ARN for token"
  type        = string
}

variable "enable_container_insights" {
  description = "Enable ECS Container Insights"
  type        = bool
  default     = true
}

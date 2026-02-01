variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-1"
}

variable "environment" {
  description = "Environment name (prod, staging, dev)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "api_service_cpu" {
  description = "CPU units for API service (256, 512, 1024, etc.)"
  type        = number
  default     = 256
}

variable "api_service_memory" {
  description = "Memory for API service in MB"
  type        = number
  default     = 512
}

variable "sqs_consumer_cpu" {
  description = "CPU units for SQS consumer service"
  type        = number
  default     = 256
}

variable "sqs_consumer_memory" {
  description = "Memory for SQS consumer service in MB"
  type        = number
  default     = 512
}

variable "api_service_port" {
  description = "Port for API service"
  type        = number
  default     = 8000
}

variable "sqs_poll_interval" {
  description = "SQS polling interval in seconds"
  type        = number
  default     = 30
}

variable "enable_monitoring" {
  description = "Enable Prometheus and Grafana monitoring"
  type        = bool
  default     = true
}

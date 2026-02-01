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

variable "iam_user_name" {
  description = "IAM user name to attach the S3 public access policy to"
  type        = string
  default     = "avanan-candidate-2"
}

# Monitoring Configuration Variables
# These variables control the monitoring and alerting behavior

variable "monitoring_alarm_threshold_cpu" {
  description = "CPU utilization threshold for ECS alarms (percentage)"
  type        = number
  default     = 80
}

variable "monitoring_alarm_threshold_memory" {
  description = "Memory utilization threshold for ECS alarms (percentage)"
  type        = number
  default     = 85
}

variable "monitoring_alarm_threshold_5xx" {
  description = "5XX error count threshold for ALB alarms"
  type        = number
  default     = 10
}

variable "monitoring_alarm_threshold_4xx" {
  description = "4XX error count threshold for ALB alarms"
  type        = number
  default     = 100
}

variable "monitoring_alarm_threshold_latency" {
  description = "Response time threshold for ALB alarms (seconds)"
  type        = number
  default     = 5
}

variable "monitoring_alarm_threshold_sqs_messages" {
  description = "SQS message count threshold for alarms"
  type        = number
  default     = 1000
}

variable "monitoring_alarm_threshold_sqs_age" {
  description = "SQS message age threshold for alarms (seconds)"
  type        = number
  default     = 600
}

variable "sns_email_subscription" {
  description = "Email address for SNS notifications (optional)"
  type        = string
  default     = ""
}

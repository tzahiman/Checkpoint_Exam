output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "Application Load Balancer ARN"
  value       = module.alb.alb_arn
}

output "s3_bucket_name" {
  description = "S3 bucket name for email storage"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.s3.bucket_arn
}

output "sqs_queue_url" {
  description = "SQS queue URL"
  value       = module.sqs.queue_url
}

output "sqs_queue_arn" {
  description = "SQS queue ARN"
  value       = module.sqs.queue_arn
}

output "ecs_cluster_id" {
  description = "ECS cluster ID"
  value       = module.ecs.cluster_id
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = module.ecs.cluster_arn
}

output "api_service_name" {
  description = "API service name"
  value       = module.ecs.api_service_name
}

output "sqs_consumer_service_name" {
  description = "SQS consumer service name"
  value       = module.ecs.sqs_consumer_service_name
}

output "ecr_api_repository_url" {
  description = "ECR repository URL for API service"
  value       = module.ecr.api_service_repository_url
}

output "ecr_sqs_consumer_repository_url" {
  description = "ECR repository URL for SQS consumer"
  value       = module.ecr.sqs_consumer_repository_url
}

output "ssm_token_parameter_name" {
  description = "SSM parameter name for API auth"
  value       = module.ssm.api_token_parameter_name
}

output "api_auth_value" {
  description = "Generated API auth value (use in Authorization header or request body); retrieve once after apply"
  value       = random_password.api_auth.result
  sensitive   = true
}

output "api_endpoint" {
  description = "API endpoint URL"
  value       = "http://${module.alb.alb_dns_name}/api/email"
}

output "api_service_repository_url" {
  description = "ECR repository URL for API service"
  value       = aws_ecr_repository.api_service.repository_url
}

output "sqs_consumer_repository_url" {
  description = "ECR repository URL for SQS consumer"
  value       = aws_ecr_repository.sqs_consumer.repository_url
}

output "api_service_repository_arn" {
  description = "ECR repository ARN for API service"
  value       = aws_ecr_repository.api_service.arn
}

output "sqs_consumer_repository_arn" {
  description = "ECR repository ARN for SQS consumer"
  value       = aws_ecr_repository.sqs_consumer.arn
}

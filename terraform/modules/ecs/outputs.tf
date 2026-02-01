output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "api_service_name" {
  description = "API service name"
  value       = aws_ecs_service.api_service.name
}

output "sqs_consumer_service_name" {
  description = "SQS consumer service name"
  value       = aws_ecs_service.sqs_consumer.name
}

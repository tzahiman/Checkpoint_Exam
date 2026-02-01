output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "api_service_name" {
  description = "API service name"
  value       = aws_ecs_service.api_service.name
}

output "sqs_consumer_service_name" {
  description = "SQS consumer service name"
  value       = aws_ecs_service.sqs_consumer.name
}

output "api_service_task_role_name" {
  description = "API service task role name"
  value       = aws_iam_role.ecs_task_api.name
}

output "api_service_task_role_arn" {
  description = "API service task role ARN"
  value       = aws_iam_role.ecs_task_api.arn
}

output "sqs_consumer_task_role_name" {
  description = "SQS consumer task role name"
  value       = aws_iam_role.ecs_task_sqs_consumer.name
}

output "sqs_consumer_task_role_arn" {
  description = "SQS consumer task role ARN"
  value       = aws_iam_role.ecs_task_sqs_consumer.arn
}

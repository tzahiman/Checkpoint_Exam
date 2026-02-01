output "queue_url" {
  description = "SQS queue URL"
  value       = aws_sqs_queue.email_queue.id
}

output "queue_arn" {
  description = "SQS queue ARN"
  value       = aws_sqs_queue.email_queue.arn
}

output "queue_name" {
  description = "SQS queue name"
  value       = aws_sqs_queue.email_queue.name
}

output "dlq_url" {
  description = "Dead Letter Queue URL"
  value       = aws_sqs_queue.dlq.id
}

output "dlq_arn" {
  description = "Dead Letter Queue ARN"
  value       = aws_sqs_queue.dlq.arn
}

# SQS Queue for email messages
resource "aws_sqs_queue" "email_queue" {
  name                      = "${var.project_name}-${var.environment}-email-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds  = 345600  # 4 days
  receive_wait_time_seconds = 20      # Long polling

  tags = {
    Name        = "${var.project_name}-email-queue"
    Environment = var.environment
  }
}

# Dead Letter Queue
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.project_name}-${var.environment}-email-dlq"
  message_retention_seconds = 1209600  # 14 days

  tags = {
    Name        = "${var.project_name}-email-dlq"
    Environment = var.environment
  }
}

# Redrive Policy
resource "aws_sqs_queue_redrive_policy" "email_queue" {
  queue_url = aws_sqs_queue.email_queue.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

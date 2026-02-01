# Monitoring Configuration for AWS Infrastructure
# This file implements comprehensive monitoring using CloudWatch

# SNS Topic for Alerts
resource "aws_sns_topic" "monitoring_alerts" {
  count = var.enable_monitoring ? 1 : 0
  name  = "${var.project_name}-${var.environment}-monitoring-alerts"
}

# SNS Email Subscription (if email provided)
resource "aws_sns_topic_subscription" "email_subscription" {
  count     = var.enable_monitoring && var.sns_email_subscription != "" ? 1 : 0
  topic_arn = aws_sns_topic.monitoring_alerts[0].arn
  protocol  = "email"
  endpoint  = var.sns_email_subscription
}

# CloudWatch Alarms for ALB
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_ELB_5XX"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = var.monitoring_alarm_threshold_5xx
  alarm_description   = "ALB 5XX error rate is too high"
  dimensions = {
    LoadBalancer = module.alb.alb_arn
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts[0].arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_4xx_errors" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-alb-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_ELB_4XX"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = var.monitoring_alarm_threshold_4xx
  alarm_description   = "ALB 4XX error rate is too high"
  dimensions = {
    LoadBalancer = module.alb.alb_arn
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts[0].arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_high_latency" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-alb-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = var.monitoring_alarm_threshold_latency
  alarm_description   = "ALB target response time is too high"
  dimensions = {
    LoadBalancer = module.alb.alb_arn
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts[0].arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_low_request_count" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-alb-low-request-count"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "RequestCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "ALB request count is suspiciously low"
  dimensions = {
    LoadBalancer = module.alb.alb_arn
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts[0].arn]
}

# CloudWatch Alarms for ECS Services
resource "aws_cloudwatch_metric_alarm" "ecs_api_service_cpu_high" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-ecs-api-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.monitoring_alarm_threshold_cpu
  alarm_description   = "API service CPU utilization is too high"
  dimensions = {
    ClusterName = module.ecs.cluster_name
    ServiceName = module.ecs.api_service_name
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts[0].arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_api_service_memory_high" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-ecs-api-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.monitoring_alarm_threshold_memory
  alarm_description   = "API service memory utilization is too high"
  dimensions = {
    ClusterName = module.ecs.cluster_name
    ServiceName = module.ecs.api_service_name
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts[0].arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_sqs_consumer_cpu_high" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-ecs-sqs-consumer-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.monitoring_alarm_threshold_cpu
  alarm_description   = "SQS consumer service CPU utilization is too high"
  dimensions = {
    ClusterName = module.ecs.cluster_name
    ServiceName = module.ecs.sqs_consumer_service_name
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts[0].arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_service_running_tasks_low" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-ecs-running-tasks-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "ECS service has fewer running tasks than expected"
  dimensions = {
    ClusterName = module.ecs.cluster_name
    ServiceName = module.ecs.api_service_name
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts[0].arn]
}

# CloudWatch Alarms for SQS
resource "aws_cloudwatch_metric_alarm" "sqs_queue_messages_high" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-sqs-messages-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.monitoring_alarm_threshold_sqs_messages
  alarm_description   = "SQS queue has too many messages waiting"
  dimensions = {
    QueueName = module.sqs.queue_name
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts[0].arn]
}

resource "aws_cloudwatch_metric_alarm" "sqs_queue_age_old" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-sqs-messages-age-old"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Maximum"
  threshold           = var.monitoring_alarm_threshold_sqs_age
  alarm_description   = "SQS queue messages are getting too old"
  dimensions = {
    QueueName = module.sqs.queue_name
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts[0].arn]
}

resource "aws_cloudwatch_metric_alarm" "sqs_empty_receives" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-sqs-empty-receives"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "NumberOfEmptyReceives"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "SQS queue is receiving too many empty poll responses"
  dimensions = {
    QueueName = module.sqs.queue_name
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts[0].arn]
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs_logs" {
  count             = var.enable_monitoring ? 1 : 0
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = 30
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# CloudWatch Log Group for ALB
resource "aws_cloudwatch_log_group" "alb_logs" {
  count             = var.enable_monitoring ? 1 : 0
  name              = "/alb/${var.project_name}-${var.environment}"
  retention_in_days = 30
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Outputs for monitoring resources
output "sns_topic_arn" {
  description = "SNS topic ARN for monitoring alerts"
  value       = var.enable_monitoring ? aws_sns_topic.monitoring_alerts[0].arn : null
}

output "cloudwatch_log_group_ecs_arn" {
  description = "CloudWatch log group ARN for ECS"
  value       = var.enable_monitoring ? aws_cloudwatch_log_group.ecs_logs[0].arn : null
}

output "cloudwatch_log_group_alb_arn" {
  description = "CloudWatch log group ARN for ALB"
  value       = var.enable_monitoring ? aws_cloudwatch_log_group.alb_logs[0].arn : null
}

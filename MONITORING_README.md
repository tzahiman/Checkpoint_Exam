# Monitoring Integration Summary

## Overview
This document describes the monitoring integration added to the Terraform infrastructure for comprehensive observability using AWS CloudWatch.

## Files Created

### 1. `monitoring.tf`
Main monitoring configuration file containing:
- **SNS Topic** for alerting
- **CloudWatch Alarms** for:
  - ALB (Application Load Balancer) metrics
  - ECS (Elastic Container Service) metrics
  - SQS (Simple Queue Service) metrics
- **CloudWatch Log Groups** for centralized logging
- **Outputs** for monitoring resource ARNs

### 2. Monitoring `variables.tf`
Configurable variables for monitoring thresholds:
- CPU utilization thresholds
- Memory utilization thresholds
- ALB error rate thresholds
- Response time thresholds
- SQS message thresholds
- SNS email subscription

## Monitoring Components

### SNS Topic for Alerts
- Creates an SNS topic: `${project_name}-${environment}-monitoring-alerts`
- Supports email subscriptions for notifications
- Integrates with CloudWatch alarms

### CloudWatch Alarms

#### ALB Monitoring
- `alb_5xx_errors`: Alerts when 5XX error rate exceeds threshold
- `alb_4xx_errors`: Alerts when 4XX error rate exceeds threshold  
- `alb_high_latency`: Alerts when response time exceeds threshold
- `alb_low_request_count`: Alerts when request count is suspiciously low

#### ECS Monitoring
- `ecs_api_service_cpu_high`: Alerts when API service CPU usage is too high
- `ecs_api_service_memory_high`: Alerts when API service memory usage is too high
- `ecs_sqs_consumer_cpu_high`: Alerts when SQS consumer CPU usage is too high
- `ecs_service_running_tasks_low`: Alerts when running tasks drop below expected

#### SQS Monitoring
- `sqs_queue_messages_high`: Alerts when queue has too many messages
- `sqs_queue_age_old`: Alerts when messages are getting too old
- `sqs_empty_receives`: Alerts when there are too many empty poll responses

### CloudWatch Log Groups
- `/ecs/${project_name}-${environment}`: For ECS container logs
- `/alb/${project_name}-${environment}`: For ALB access logs

## Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `enable_monitoring` | `true` | Enable/disable all monitoring |
| `monitoring_alarm_threshold_cpu` | `80` | CPU threshold for ECS alarms (%) |
| `monitoring_alarm_threshold_memory` | `85` | Memory threshold for ECS alarms (%) |
| `monitoring_alarm_threshold_5xx` | `10` | 5XX error threshold for ALB |
| `monitoring_alarm_threshold_4xx` | `100` | 4XX error threshold for ALB |
| `monitoring_alarm_threshold_latency` | `5` | Response time threshold (seconds) |
| `monitoring_alarm_threshold_sqs_messages` | `1000` | SQS message count threshold |
| `monitoring_alarm_threshold_sqs_age` | `600` | SQS message age threshold (seconds) |
| `sns_email_subscription` | `""` | Email for SNS notifications |

## Viewing Monitoring and Logs from AWS CLI

### Prerequisites
Ensure AWS CLI is configured with appropriate credentials:
```bash
aws configure
# OR
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-west-1
```

### CloudWatch Alarms

#### List All Alarms
```bash
aws cloudwatch describe-alarms \
  --alarm-names-prefix "email-service-dev" \
  --query 'MetricAlarms[].{Name:AlarmName,State:StateValue,Threshold:Threshold}'
```

#### Get Alarm State
```bash
aws cloudwatch describe-alarms \
  --alarm-names "email-service-dev-alb-5xx-errors"
```

#### View Alarm History
```bash
aws cloudwatch describe-alarm-history \
  --alarm-name "email-service-dev-ecs-api-cpu-high" \
  --history-item-type "StateUpdate"
```

#### Get Metric Data (Last 24 Hours)
```bash
aws cloudwatch get-metric-data \
  --metric-data-queries '[{"Id":"cpu","MetricStat":{"Metric":{"Namespace":"AWS/ECS","MetricName":"CPUUtilization","Dimensions":[{"Name":"ClusterName","Value":"email-service-dev-cluster"},{"Name":"ServiceName","Value":"email-service-dev-api-service"}]},"Period":60,"Stat":"Average"},"ReturnData":true}]' \
  --start-time "$(date -u -v-1d +%Y-%m-%dT%H:%M:%SZ)" \
  --end-time "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

### SNS Topic and Subscriptions

#### List SNS Topics
```bash
aws sns list-topics \
  --query 'Topics[?contains(TopicArn, `email-service-dev`)]'
```

#### List Subscriptions to Topic
```bash
aws sns list-subscriptions-by-topic \
  --topic-arn "arn:aws:sns:us-west-1:123456789012:email-service-dev-monitoring-alerts"
```

#### Publish Test Message
```bash
aws sns publish \
  --topic-arn "arn:aws:sns:us-west-1:123456789012:email-service-dev-monitoring-alerts" \
  --message "Test message from AWS CLI" \
  --subject "Test Alert"
```

### CloudWatch Logs

#### List Log Groups
```bash
aws logs describe-log-groups \
  --log-group-name-prefix "/ecs/email-service-dev"
```

```bash
aws logs describe-log-groups \
  --log-group-name-prefix "/alb/email-service-dev"
```

#### View Log Streams (ECS)
```bash
aws logs describe-log-streams \
  --log-group-name "/ecs/email-service-dev/api-service" \
  --order-by "LastEventTime" \
  --descending \
  --limit 5
```

#### View Log Streams (ALB)
```bash
aws logs describe-log-streams \
  --log-group-name "/alb/email-service-dev" \
  --order-by "LastEventTime" \
  --descending \
  --limit 5
```

#### Get Log Events
```bash
aws logs get-log-events \
  --log-group-name "/ecs/email-service-dev/api-service" \
  --log-stream-name "your-log-stream-name" \
  --start-from-head \
  --limit 50
```

#### Tail Logs in Real-Time
```bash
aws logs tail "/ecs/email-service-dev/api-service" \
  --follow \
  --format short
```

### CloudWatch Insights Queries

#### Query ECS Logs (Last Hour)
```bash
aws logs start-query \
  --log-group-name "/ecs/email-service-dev/api-service" \
  --start-query "$(date -u -v-1H +%s)000" \
  --end-query "$(date +%s)000" \
  --query-string 'fields @timestamp, @message | sort @timestamp desc | limit 50'
```

#### Query ALB Logs for Errors (Last Hour)
```bash
aws logs start-query \
  --log-group-name "/alb/email-service-dev" \
  --start-query "$(date -u -v-1H +%s)000" \
  --end-query "$(date +%s)000" \
  --query-string 'fields @timestamp, elb_status_code, client_ip | filter elb_status_code >= 400 | sort @timestamp desc | limit 100'
```

#### Get Query Results
```bash
aws logs get-query-results \
  --query-id "your-query-id-from-start-query"
```

### ECS Container Insights

#### List Clusters with Insights
```bash
aws ecs list-clusters
```

#### Describe Cluster
```bash
aws ecs describe-clusters \
  --clusters "email-service-dev-cluster" \
  --include "SETTINGS"
```

#### View Service Metrics (via CloudWatch)
```bash
aws cloudwatch list-metrics \
  --namespace "AWS/ECS" \
  --dimensions "Name=ClusterName,Value=email-service-dev-cluster" \
  "Name=ServiceName,Value=email-service-dev-api-service"
```

### SQS Monitoring via CLI

#### Get Queue Attributes
```bash
aws sqs get-queue-attributes \
  --queue-url "https://sqs.us-west-1.amazonaws.com/123456789012/email-service-dev-email-queue" \
  --attribute-names All
```

#### Get Approximate Message Count
```bash
aws sqs get-queue-attributes \
  --queue-url "https://sqs.us-west-1.amazonaws.com/123456789012/email-service-dev-email-queue" \
  --attribute-names ApproximateNumberOfMessages,ApproximateNumberOfMessagesNotVisible,ApproximateAgeOfOldestMessage
```

### ALB Monitoring via CLI

#### Describe Load Balancers
```bash
aws elbv2 describe-load-balancers \
  --names "email-service-dev-alb"
```

#### Describe Target Health
```bash
aws elbv2 describe-target-health \
  --target-group-arn "arn:aws:elasticloadbalancing:us-west-1:123456789012:targetgroup/email-service-dev-api-tg/abc123"
```

#### Get ALB Metrics
```bash
aws cloudwatch get-metric-statistics \
  --namespace "AWS/ApplicationELB" \
  --metric-name "RequestCount" \
  --dimensions "Name=LoadBalancer,Value=app/email-service-dev-alb/abc123" \
  --start-time "$(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ)" \
  --end-time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --period 300 \
  --statistics Sum
```

### Helpful Aliases

Add these to your `~/.bashrc` or `~/.zshrc`:

```bash
# Monitoring aliases
alias cw-alarms='aws cloudwatch describe-alarms --alarm-names-prefix "email-service-dev"'
alias cw-metrics='aws cloudwatch list-metrics --namespace "AWS/ECS"'
alias cw-logs-ecs='aws logs describe-log-groups --log-group-name-prefix "/ecs/email-service-dev"'
alias cw-logs-alb='aws logs describe-log-groups --log-group-name-prefix "/alb/email-service-dev"'
alias sqs-stats='aws sqs get-queue-attributes --queue-url QUEUE_URL --attribute-names All'
alias ecs-status='aws ecs describe-services --cluster email-service-dev-cluster --services email-service-dev-api-service'
```

### One-Liner Health Check Script

```bash
#!/bin/bash
# Quick health check for all monitored components

echo "=== ALB Status ==="
aws elbv2 describe-load-balancers --names "email-service-dev-alb" --query 'LoadBalancers[0].State'

echo "=== ECS Service Status ==="
aws ecs describe-services --cluster email-service-dev-cluster --services email-service-dev-api-service --query 'services[0].runningCount'

echo "=== SQS Queue Depth ==="
aws sqs get-queue-attributes --queue-url "https://sqs.us-west-1.amazonaws.com/123456789012/email-service-dev-email-queue" --attribute-names ApproximateNumberOfMessages --query 'Attributes.ApproximateNumberOfMessages'

echo "=== Active Alarms ==="
aws cloudwatch describe-alarms --alarm-names-prefix "email-service-dev" --query 'MetricAlarms[?StateValue==`ALARM`].AlarmName'
```

## Integration with Existing Infrastructure

The monitoring module integrates with:
- **ALB**: Uses `module.alb.alb_arn` for dimensions
- **ECS**: Uses `module.ecs.cluster_name`, `module.ecs.api_service_name`, `module.ecs.sqs_consumer_service_name`
- **SQS**: Uses `module.sqs.queue_name`

## Required Module Outputs

The following outputs were added to support monitoring:

### ECS Module (`modules/ecs/outputs.tf`)
```hcl
output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}
```

### SQS Module (`modules/sqs/outputs.tf`)
```hcl
output "queue_name" {
  description = "SQS queue name"
  value       = aws_sqs_queue.email_queue.name
}
```

## Outputs Provided

After applying the monitoring configuration:

| Output | Description |
|--------|-------------|
| `sns_topic_arn` | ARN of the SNS topic for alerts |
| `cloudwatch_log_group_ecs_arn` | ARN of the ECS log group |
| `cloudwatch_log_group_alb_arn` | ARN of the ALB log group |

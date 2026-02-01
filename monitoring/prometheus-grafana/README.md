# Monitoring Setup - Prometheus & Grafana

This directory contains the monitoring setup for the microservices using Prometheus and Grafana.

## Components

- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards

## Running Locally

```bash
# Start Prometheus and Grafana
docker-compose up -d

# Access Grafana
# URL: http://localhost:3000
# Username: admin
# Password: admin

# Access Prometheus
# URL: http://localhost:9090
```

## Metrics Collected

### API Service Metrics
- `api_requests_total`: Total API requests by method, endpoint, and status
- `api_request_duration_seconds`: Request duration histogram
- `api_validation_errors_total`: Validation errors by type

### SQS Consumer Metrics
- `sqs_messages_processed_total`: Total messages processed
- `sqs_messages_failed_total`: Total messages failed
- `s3_uploads_success_total`: Successful S3 uploads
- `s3_uploads_failed_total`: Failed S3 uploads
- `message_processing_duration_seconds`: Processing duration
- `sqs_queue_messages_visible`: Current visible messages in queue

## Grafana Dashboards

Default dashboards are provisioned automatically. You can create custom dashboards in Grafana UI.

## Production Deployment

For production, deploy Prometheus and Grafana on ECS or EC2 instances and configure them to scrape metrics from the microservices.

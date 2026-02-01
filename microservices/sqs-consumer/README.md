# SQS Consumer Service - Microservice 2

Service that polls SQS messages and uploads them to S3 bucket.

## Features

- Polls SQS queue for messages
- Processes email data from messages
- Uploads to S3 with organized folder structure
- Prometheus metrics for monitoring
- Error handling and retry logic
- Long polling for efficient message retrieval

## Environment Variables

- `SQS_QUEUE_URL`: SQS queue URL to poll (required)
- `S3_BUCKET_NAME`: S3 bucket name for storing emails (required)
- `SQS_POLL_INTERVAL`: Polling interval in seconds (default: 30)
- `AWS_REGION`: AWS region (default: us-west-1)
- `METRICS_PORT`: Port for Prometheus metrics (default: 9090)

## S3 Storage Structure

Emails are stored in S3 with the following structure:
```
emails/
  YYYY/
    MM/
      DD/
        email-{timestamp}-{sender_hash}.json
```

Example:
```
emails/2023/09/01/email-1693561101-1234.json
```

## Running Locally

```bash
# Install dependencies
pip install -r requirements.txt

# Set environment variables
export SQS_QUEUE_URL="https://sqs.us-west-1.amazonaws.com/123456789/test-queue"
export S3_BUCKET_NAME="devops-exam-prod-email-storage"
export SQS_POLL_INTERVAL=30
export AWS_REGION="us-west-1"

# Run the service
python -m app.main
```

## Testing

```bash
# Install test dependencies
pip install -r tests/requirements.txt

# Run tests
pytest tests/
```

## Docker

```bash
# Build image
docker build -t sqs-consumer .

# Run container
docker run \
  -e SQS_QUEUE_URL="your-queue-url" \
  -e S3_BUCKET_NAME="your-bucket-name" \
  -e SQS_POLL_INTERVAL=30 \
  -e AWS_REGION="us-west-1" \
  sqs-consumer
```

## Metrics

Prometheus metrics are exposed on port 9090:

- `sqs_messages_processed_total`: Total messages processed
- `sqs_messages_failed_total`: Total messages failed
- `s3_uploads_success_total`: Successful S3 uploads
- `s3_uploads_failed_total`: Failed S3 uploads
- `message_processing_duration_seconds`: Processing duration histogram
- `sqs_queue_messages_visible`: Current visible messages in queue

Access metrics at: `http://localhost:9090/metrics`

# API Service - Microservice 1

REST API service that receives email data, validates authentication tokens and data fields, then publishes validated messages to SQS.

## Features

- REST API endpoint for receiving email data
- Token validation using AWS SSM Parameter Store
- Data validation (ensures all 4 required fields are present)
- SQS message publishing
- Prometheus metrics
- Health check endpoint
- Comprehensive error handling

## Environment Variables

- `SQS_QUEUE_URL`: SQS queue URL for publishing messages
- `SSM_TOKEN_PARAMETER`: SSM parameter path for authentication token (default: `/devops-exam/prod/api/token`)
- `AWS_REGION`: AWS region (default: `us-west-1`)
- `PORT`: Service port (default: `8000`)

## API Endpoints

### POST /api/email

Receive and process email data.

**Request Body:**
```json
{
  "data": {
    "email_subject": "Happy new year!",
    "email_sender": "John doe",
    "email_timestamp": "1693561101",
    "email_content": "Just want to say... Happy new year!!!"
  },
  "token": "$DJISA<$#45ex3RtYr"
}
```

**Success Response (200):**
```json
{
  "status": "success",
  "message": "Email data received and queued successfully",
  "email_subject": "Happy new year!"
}
```

**Error Responses:**
- `401`: Invalid token
- `400`: Invalid data (missing required fields)
- `500`: Server error

### GET /health

Health check endpoint.

### GET /metrics

Prometheus metrics endpoint.

## Running Locally

```bash
# Install dependencies
pip install -r requirements.txt

# Set environment variables
export SQS_QUEUE_URL="https://sqs.us-west-1.amazonaws.com/123456789/test-queue"
export SSM_TOKEN_PARAMETER="/devops-exam/prod/api/token"
export AWS_REGION="us-west-1"

# Run the service
uvicorn app.main:app --host 0.0.0.0 --port 8000
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
docker build -t api-service .

# Run container
docker run -p 8000:8000 \
  -e SQS_QUEUE_URL="your-queue-url" \
  -e SSM_TOKEN_PARAMETER="/devops-exam/prod/api/token" \
  -e AWS_REGION="us-west-1" \
  api-service
```

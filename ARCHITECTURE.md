# Architecture Documentation

## System Architecture

This document describes the architecture of the DevOps exam solution.

## Overview

The system consists of two microservices deployed on AWS ECS Fargate:

1. **API Service**: REST API that receives email data, validates it, and publishes to SQS
2. **SQS Consumer**: Service that polls SQS and uploads messages to S3

## Architecture Diagram

```
Internet
   |
   v
[Application Load Balancer]
   |
   v
[ECS Fargate - API Service]
   |
   v
[SQS Queue]
   |
   v
[ECS Fargate - SQS Consumer]
   |
   v
[S3 Bucket]
```

## Components

### Infrastructure (Terraform)

#### VPC Module
- VPC with public and private subnets across 2 availability zones
- Internet Gateway for public subnets
- NAT Gateways for private subnet internet access
- Route tables and associations

#### ECS Module
- ECS Fargate cluster
- Task definitions for both services
- ECS services with auto-scaling capabilities
- IAM roles with least privilege permissions
- CloudWatch Log Groups
- Security groups

#### ALB Module
- Application Load Balancer in public subnets
- Target group for API service
- Health checks
- Security group

#### S3 Module
- S3 bucket for email storage
- Versioning enabled
- Encryption at rest
- Lifecycle policies

#### SQS Module
- SQS queue for message queuing
- Dead Letter Queue (DLQ) for failed messages
- Redrive policy

#### SSM Module
- SSM Parameter Store for secure token storage

#### ECR Module
- ECR repositories for Docker images
- Lifecycle policies

### Microservices

#### API Service (Microservice 1)

**Technology Stack:**
- Python 3.11
- FastAPI framework
- Boto3 for AWS SDK
- Prometheus client for metrics

**Features:**
- REST API endpoint `/api/email`
- Token validation from SSM Parameter Store
- Data validation (4 required fields)
- SQS message publishing
- Health check endpoint
- Prometheus metrics endpoint
- Comprehensive error handling

**Environment Variables:**
- `SQS_QUEUE_URL`: SQS queue URL
- `SSM_TOKEN_PARAMETER`: SSM parameter path
- `AWS_REGION`: AWS region
- `PORT`: Service port (default: 8000)

**Endpoints:**
- `POST /api/email`: Receive and process email data
- `GET /health`: Health check
- `GET /metrics`: Prometheus metrics

#### SQS Consumer (Microservice 2)

**Technology Stack:**
- Python 3.11
- Boto3 for AWS SDK
- Prometheus client for metrics

**Features:**
- Long polling SQS queue
- Message processing
- S3 upload with organized structure
- Prometheus metrics
- Error handling and retry logic

**Environment Variables:**
- `SQS_QUEUE_URL`: SQS queue URL
- `S3_BUCKET_NAME`: S3 bucket name
- `SQS_POLL_INTERVAL`: Polling interval in seconds
- `AWS_REGION`: AWS region
- `METRICS_PORT`: Metrics port (default: 9090)

**S3 Storage Structure:**
```
emails/
  YYYY/
    MM/
      DD/
        email-{timestamp}-{sender_hash}.json
```

## CI/CD Pipeline

### GitHub Actions Workflows

#### CI Workflows
1. **CI - API Service**
   - Runs tests
   - Builds Docker image
   - Pushes to ECR

2. **CI - SQS Consumer**
   - Runs tests
   - Builds Docker image
   - Pushes to ECR

#### CD Workflows
1. **CD - Deploy API Service**
   - Updates ECS task definition
   - Deploys to ECS service

2. **CD - Deploy SQS Consumer**
   - Updates ECS task definition
   - Deploys to ECS service

#### Infrastructure Workflow
- **Terraform Apply**: Deploys infrastructure changes

## Security

### IAM Roles
- **ECS Task Execution Role**: Permissions for ECS to pull images and write logs
- **API Service Task Role**: Permissions to read SSM parameters and publish to SQS
- **SQS Consumer Task Role**: Permissions to read from SQS and write to S3

### Security Groups
- ALB security group: Allows HTTP/HTTPS from internet
- ECS tasks security group: Allows traffic from ALB only

### Secrets Management
- API token stored in SSM Parameter Store (SecureString)
- Encrypted at rest
- Accessed via IAM roles

### Network Security
- Services deployed in private subnets
- No direct internet access
- NAT Gateway for outbound connections

## Monitoring

### CloudWatch
- Container logs
- ECS service metrics
- Container Insights (if enabled)

### Prometheus
- Application metrics
- Custom business metrics

### Grafana
- Visualization dashboards
- Alerting (if configured)

## Scalability

### ECS Auto Scaling
- Can be configured based on:
  - CPU utilization
  - Memory utilization
  - Request count
  - Custom metrics

### SQS
- Automatically scales with message volume
- Long polling for efficient message retrieval

### S3
- Unlimited storage capacity
- Automatic scaling

## High Availability

- Services deployed across 2 availability zones
- ALB with health checks
- ECS service with multiple tasks
- SQS with DLQ for error handling

## Cost Optimization

- ECS Fargate: Pay only for running tasks
- S3: Lifecycle policies to delete old versions
- ECR: Lifecycle policies to keep only recent images
- NAT Gateways: Can be replaced with NAT Instances for cost savings (not recommended for production)

## Best Practices Implemented

1. **Infrastructure as Code**: All resources defined in Terraform
2. **Modular Design**: Reusable Terraform modules
3. **Security**: Least privilege IAM, encrypted secrets, private subnets
4. **Monitoring**: Comprehensive logging and metrics
5. **Testing**: Unit tests for both services
6. **CI/CD**: Automated build and deployment
7. **Error Handling**: Comprehensive error handling and DLQ
8. **Documentation**: Detailed README and architecture docs

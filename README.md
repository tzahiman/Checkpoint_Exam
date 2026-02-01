# DevOps Exam Solution - Microservices on AWS ECS

This project implements a complete DevOps solution with two microservices deployed on AWS ECS, using Terraform for Infrastructure as Code, and GitHub Actions for CI/CD.

## Architecture Overview

- **Microservice 1**: REST API that receives requests via Application Load Balancer, validates tokens from SSM Parameter Store, and publishes validated data to SQS
- **Microservice 2**: SQS consumer that polls messages and uploads them to S3
- **Infrastructure**: ECS Fargate, Application Load Balancer, S3, SQS, SSM Parameter Store, VPC
- **CI/CD**: GitHub Actions for building Docker images and deploying to ECS
- **Monitoring**: Prometheus and Grafana for observability

## Project Structure

```
.
├── terraform/
│   ├── modules/
│   │   ├── vpc/
│   │   ├── ecs/
│   │   ├── alb/
│   │   ├── s3/
│   │   ├── sqs/
│   │   └── ssm/
│   ├── environments/
│   │   └── prod/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── backend.tf
├── microservices/
│   ├── api-service/
│   │   ├── app/
│   │   ├── tests/
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── README.md
│   └── sqs-consumer/
│       ├── app/
│       ├── tests/
│       ├── Dockerfile
│       ├── requirements.txt
│       └── README.md
├── .github/
│   └── workflows/
│       ├── ci-api-service.yml
│       ├── ci-sqs-consumer.yml
│       ├── cd-api-service.yml
│       └── cd-sqs-consumer.yml
└── monitoring/
    └── prometheus-grafana/
```

## Prerequisites

1. AWS Account with appropriate permissions
2. Terraform >= 1.0
3. AWS CLI configured
4. Docker installed
5. Python 3.9+
6. GitHub repository (public for exam submission)

## Setup Instructions

### 1. Configure AWS Credentials

```bash
aws configure
```

### 2. Create S3 Backend for Terraform State

```bash
aws s3 mb s3://your-terraform-state-bucket
aws s3api put-bucket-versioning --bucket your-terraform-state-bucket --versioning-configuration Status=Enabled
```

### 3. Configure Terraform Backend

Edit `terraform/backend.tf` and update the bucket name:

```hcl
bucket = "your-terraform-state-bucket"
```

### 4. Set Terraform Variables

Create `terraform/environments/prod/terraform.tfvars`:

```hcl
aws_region = "us-west-1"
environment = "prod"
project_name = "devops-exam"

# ECS Configuration
api_service_cpu = 256
api_service_memory = 512
sqs_consumer_cpu = 256
sqs_consumer_memory = 512

# Application Configuration
api_service_port = 8000
sqs_poll_interval = 30

# Token for API validation
api_token = "your-secure-token-here"
```

### 5. Initialize and Apply Terraform

```bash
cd terraform/environments/prod
terraform init
terraform plan
terraform apply
```

### 6. Configure GitHub Secrets

In your GitHub repository, add the following secrets:

- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
- `AWS_REGION`: AWS region (e.g., us-west-1)
- `ECR_REPOSITORY_API`: ECR repository for API service
- `ECR_REPOSITORY_SQS_CONSUMER`: ECR repository for SQS consumer
- `ECS_CLUSTER_NAME`: ECS cluster name
- `ECS_SERVICE_API_NAME`: ECS service name for API
- `ECS_SERVICE_SQS_CONSUMER_NAME`: ECS service name for SQS consumer

### 7. Build and Push Docker Images

The GitHub Actions workflows will automatically:
- Build Docker images on push to main
- Push to ECR
- Deploy to ECS

Or manually:

```bash
# Build and push API service
cd microservices/api-service
docker build -t api-service .
docker tag api-service:latest <account-id>.dkr.ecr.<region>.amazonaws.com/api-service:latest
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/api-service:latest

# Build and push SQS consumer
cd microservices/sqs-consumer
docker build -t sqs-consumer .
docker tag sqs-consumer:latest <account-id>.dkr.ecr.<region>.amazonaws.com/sqs-consumer:latest
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/sqs-consumer:latest
```

## Testing

### Test API Service Locally

```bash
cd microservices/api-service
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
pytest tests/
```

### Test SQS Consumer Locally

```bash
cd microservices/sqs-consumer
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pytest tests/
```

### Manual API Testing

```bash
# Get ALB endpoint from Terraform outputs
ALB_ENDPOINT=$(terraform output -raw alb_dns_name)

# Test API with valid token
curl -X POST http://${ALB_ENDPOINT}/api/email \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "email_subject": "Test Email",
      "email_sender": "test@example.com",
      "email_timestamp": "1693561101",
      "email_content": "This is a test email"
    },
    "token": "your-token-from-ssm"
  }'
```

## Monitoring

### Access Prometheus

Prometheus is deployed as a sidecar container. Access metrics at:
- `http://<service-endpoint>:9090/metrics`

### Access Grafana

Grafana dashboard URL will be available in Terraform outputs after deployment.

## Cleanup

To destroy all resources:

```bash
cd terraform/environments/prod
terraform destroy
```

## Best Practices Implemented

1. **Infrastructure as Code**: All AWS resources defined in Terraform modules
2. **Modular Design**: Reusable Terraform modules for each component
3. **Security**: Secrets stored in SSM Parameter Store, IAM roles with least privilege
4. **CI/CD**: Automated build and deployment via GitHub Actions
5. **Testing**: Unit tests for both microservices
6. **Monitoring**: Prometheus metrics and Grafana dashboards
7. **Error Handling**: Comprehensive error handling and logging
8. **Documentation**: Detailed README and code comments

## Troubleshooting

### ECS Service Not Starting

- Check CloudWatch Logs for container errors
- Verify IAM roles have correct permissions
- Ensure security groups allow traffic

### API Service Not Receiving Requests

- Verify ALB target group health checks
- Check security group rules
- Verify ECS service is running

### SQS Consumer Not Processing Messages

- Check CloudWatch Logs
- Verify SQS queue permissions
- Ensure S3 bucket permissions are correct

## License

This project is created for educational/exam purposes.

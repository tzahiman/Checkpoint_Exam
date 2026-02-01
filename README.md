# DevOps Exam Solution - Microservices on AWS ECS

This project implements a complete DevOps solution with two microservices deployed on AWS ECS, using Terraform for Infrastructure as Code, and GitHub Actions for CI/CD.

## Architecture Overview

- **Microservice 1**: REST API that receives requests via Application Load Balancer, validates auth from SSM Parameter Store, and publishes validated data to SQS
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
│   │   ├── ssm/
│   │   └── ecr/
│   ├── environments/
│   │   └── prod/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── backend.tf
│   └── backend.s3.tfvars.example
├── scripts/
│   ├── setup.sh
│   └── bootstrap-backend.sh
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
│       ├── cd-sqs-consumer.yml
│       └── terraform-apply.yml
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

## Deployment

### CI/CD Secrets

The following secrets and vars are required for the CI/CD pipelines. Here's how to obtain them:

*   **`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`**:
    These are credentials for an IAM user with programmatic access. It is recommended to create a dedicated IAM user for CI/CD purposes with the necessary permissions.
    *   **How to get**:
        Use the AWS CLI to create an access key for an IAM user.
        `aws iam create-access-key --user-name <your-ci-cd-iam-user>`
        Make sure to save the `AccessKeyId` and `SecretAccessKey` from the output, as they will only be shown once.

*   **`AWS_REGION`**:
    The AWS region where your resources are deployed (e.g., `us-east-1`, `eu-west-2`).
    *   **How to get**:
        1.  Check your AWS CLI configuration: `aws configure get region`
        2.  Refer to your Terraform configuration files (e.g., `terraform/main.tf` or `terraform/variables.tf`) for the configured region.

*   **`ECR_REPOSITORY_API`**:
    Configure as Github Variable.
    The full URI for your Amazon Elastic Container Registry (ECR) repository for the API service.
    *   **How to get**:
        `terraform output ecr_api_repository_url`

*   **`ECR_REPOSITORY_SQS_CONSUMER`**:
    Configure as Github Variable.
    The full URI for your Amazon Elastic Container Registry (ECR) repository for the SQS consumer.
    *   **How to get**:
        `terraform output ecr_sqs_consumer_repository_url`

*   **`ECS_CLUSTER_NAME`**:
    The name of your Amazon Elastic Container Service (ECS) cluster.
    *   **How to get**:
        `terraform output ecs_cluster_id`
        Alternatively, using AWS CLI:
        `aws ecs list-clusters --query 'clusterArns[]' --output text`
        (The cluster name is the last part of the ARN, e.g., `arn:aws:ecs:REGION:ACCOUNT_ID:cluster/YOUR_CLUSTER_NAME`).

*   **`ECS_SERVICE_API_NAME`**:
    The name of the ECS service running your API application within your ECS cluster.
    *   **How to get**:
        `terraform output api_service_name`
        Alternatively, using AWS CLI:
        `aws ecs list-services --cluster <your-cluster-name> --query 'serviceArns[]' --output text`
        (The service name is the last part of the ARN, e.g., `arn:aws:ecs:REGION:ACCOUNT_ID:service/YOUR_CLUSTER_NAME/YOUR_SERVICE_NAME`).

*   **`ECS_SERVICE_SQS_CONSUMER_NAME`**:
    The name of the ECS service running your SQS consumer application within your ECS cluster.
    *   **How to get**:
        `terraform output sqs_consumer_service_name`
        Alternatively, using AWS CLI:
        `aws ecs list-services --cluster <your-cluster-name> --query 'serviceArns[]' --output text`
        (The service name is the last part of the ARN, e.g., `arn:aws:ecs:REGION:ACCOUNT_ID:service/YOUR_CLUSTER_NAME/YOUR_SERVICE_NAME`).

### 1. Configure AWS Credentials

```bash
aws configure
```

### 2. Bootstrap S3 Backend (one-time)

Create the S3 bucket and DynamoDB table for Terraform state, then init with the S3 backend:

```bash
./scripts/bootstrap-backend.sh
cd terraform
terraform init 
```

The script creates terraform backend s3 bucket and lock table. To use a different region or names, set env vars before running the script: `AWS_REGION=us-west-1 BUCKET_PREFIX=devops-exam-terraform-state ./scripts/bootstrap-backend.sh`.

### 3. Set Terraform Variables

Create `terraform/environments/prod/terraform.tfvars` (see `terraform.tfvars.example`). The API auth secret is generated by Terraform and stored in SSM automatically.

### 4. Initialize and Apply Terraform

If you already ran the bootstrap (step 2):

```bash
cd terraform
terraform init
terraform plan -var-file=environments/prod/terraform.tfvars
terraform apply -var-file=environments/prod/terraform.tfvars
```

(First time: run `./scripts/bootstrap-backend.sh` from the repo root, then the commands above.)

After apply, retrieve the generated API auth value once (used for requests to `/api/email`):

```bash
terraform output -raw api_auth_value
```
Store it securely; it is also in SSM at the path shown by `terraform output ssm_token_parameter_name`.

### 5. Configure GitHub Secrets

In your GitHub repository, add the following secrets:

**For CI/CD (build & deploy):**
- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
- `AWS_REGION`: AWS region (e.g., us-west-1)
- `ECS_CLUSTER_NAME`: ECS cluster name
- `ECS_SERVICE_API_NAME`: ECS service name for API
- `ECS_SERVICE_SQS_CONSUMER_NAME`: ECS service name for SQS consumer   

**Add the following as GitHub Variables**  
- `ECR_REPOSITORY_API`: ECR repository for API service
- `ECR_REPOSITORY_SQS_CONSUMER`: ECR repository for SQS consumer  

### 6. Build and Push Docker Images

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

From the `terraform/` directory (after apply):

```bash
cd terraform

# Get ALB endpoint and auth value from Terraform outputs
ALB_ENDPOINT=$(terraform output -raw alb_dns_name)
AUTH_VALUE=$(terraform output -raw api_auth_value)

# Test API
curl -X POST http://${ALB_ENDPOINT}/api/email \
  -H "Content-Type: application/json" \
  -d "{
    \"data\": {
      \"email_subject\": \"Test Email\",
      \"email_sender\": \"test@example.com\",
      \"email_timestamp\": \"1693561101\",
      \"email_content\": \"This is a test email\"
    },
    \"token\": \"$AUTH_VALUE\"
  }"
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
cd terraform
terraform destroy -var-file=environments/prod/terraform.tfvars
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

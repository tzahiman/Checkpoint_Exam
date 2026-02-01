# Deployment Guide

This guide provides step-by-step instructions for deploying the DevOps exam solution.

## Prerequisites

1. AWS Account with appropriate permissions
2. Terraform >= 1.0 installed
3. AWS CLI configured
4. Docker installed
5. GitHub repository (public for exam submission)

## Step 1: Configure AWS Credentials

```bash
aws configure
```

Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., us-west-1)
- Default output format (json)

## Step 2: Create S3 Backend for Terraform State

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://your-terraform-state-bucket --region us-west-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Optional: Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-west-1
```

## Step 3: Configure Terraform

1. Update `terraform/backend.tf`:
   ```hcl
   bucket = "your-terraform-state-bucket"
   ```

2. Create `terraform/environments/prod/terraform.tfvars`:
   ```hcl
   aws_region = "us-west-1"
   environment = "prod"
   project_name = "devops-exam"
   
   api_service_cpu = 256
   api_service_memory = 512
   sqs_consumer_cpu = 256
   sqs_consumer_memory = 512
   
   api_service_port = 8000
   sqs_poll_interval = 30
   
   api_token = "your-secure-token-here-change-me"
   
   enable_monitoring = true
   ```

## Step 4: Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

After successful deployment, note the outputs:
- `alb_dns_name`: ALB endpoint for API
- `ecr_api_repository_url`: ECR repository for API service
- `ecr_sqs_consumer_repository_url`: ECR repository for SQS consumer
- `ssm_token_parameter_name`: SSM parameter name for token

## Step 5: Build and Push Docker Images

### Option A: Using GitHub Actions (Recommended)

1. Configure GitHub Secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION`

2. Push code to GitHub - CI workflows will automatically build and push images

### Option B: Manual Build and Push

```bash
# Get ECR login
aws ecr get-login-password --region us-west-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-west-1.amazonaws.com

# Build and push API service
cd microservices/api-service
docker build -t api-service .
docker tag api-service:latest <ecr-repo-url>/api-service:latest
docker push <ecr-repo-url>/api-service:latest

# Build and push SQS consumer
cd ../sqs-consumer
docker build -t sqs-consumer .
docker tag sqs-consumer:latest <ecr-repo-url>/sqs-consumer:latest
docker push <ecr-repo-url>/sqs-consumer:latest
```

## Step 6: Deploy Services to ECS

### Option A: Using GitHub Actions

CD workflows will automatically deploy after successful CI builds.

### Option B: Manual Deployment

```bash
# Update ECS service to use new image
aws ecs update-service \
  --cluster devops-exam-cluster \
  --service devops-exam-api-service \
  --force-new-deployment

aws ecs update-service \
  --cluster devops-exam-cluster \
  --service devops-exam-sqs-consumer \
  --force-new-deployment
```

## Step 7: Verify Deployment

1. Check ECS services are running:
   ```bash
   aws ecs describe-services \
     --cluster devops-exam-cluster \
     --services devops-exam-api-service devops-exam-sqs-consumer
   ```

2. Get ALB endpoint:
   ```bash
   terraform output alb_dns_name
   ```

3. Test API endpoint:
   ```bash
   # Get token from SSM
   TOKEN=$(aws ssm get-parameter \
     --name /devops-exam/prod/api/token \
     --with-decryption \
     --query 'Parameter.Value' \
     --output text)
   
   # Test API
   curl -X POST http://$(terraform output -raw alb_dns_name)/api/email \
     -H "Content-Type: application/json" \
     -d "{
       \"data\": {
         \"email_subject\": \"Test Email\",
         \"email_sender\": \"test@example.com\",
         \"email_timestamp\": \"1693561101\",
         \"email_content\": \"This is a test email\"
       },
       \"token\": \"$TOKEN\"
     }"
   ```

4. Check S3 bucket for uploaded emails:
   ```bash
   aws s3 ls s3://$(terraform output -raw s3_bucket_name)/emails/ --recursive
   ```

## Step 8: Monitor Services

1. **CloudWatch Logs**:
   ```bash
   aws logs tail /ecs/devops-exam/api-service --follow
   aws logs tail /ecs/devops-exam/sqs-consumer --follow
   ```

2. **ECS Console**: Check service status and task health

3. **Prometheus Metrics**: Access metrics endpoints (if configured)

## Troubleshooting

### ECS Service Not Starting
- Check CloudWatch Logs for errors
- Verify IAM roles have correct permissions
- Check security group rules
- Verify task definition is correct

### API Not Responding
- Check ALB target group health checks
- Verify ECS service is running
- Check security group allows traffic from ALB
- Review CloudWatch Logs

### SQS Consumer Not Processing
- Check CloudWatch Logs
- Verify SQS queue permissions
- Check S3 bucket permissions
- Verify environment variables are set correctly

### Terraform Errors
- Verify AWS credentials are configured
- Check S3 backend bucket exists
- Verify IAM permissions for Terraform
- Review Terraform state file

## Cleanup

To destroy all resources:

```bash
cd terraform
terraform destroy
```

**Warning**: This will delete all resources including S3 bucket contents. Make sure to backup any important data first.

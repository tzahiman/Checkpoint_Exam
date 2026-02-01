# Quick Start Guide

This guide will help you get the DevOps exam solution up and running quickly.

## Prerequisites Check

```bash
# Check Terraform
terraform version  # Should be >= 1.0

# Check AWS CLI
aws --version

# Check Docker
docker --version

# Check Python
python3 --version  # Should be >= 3.9
```

## Quick Setup (5 minutes)

### 1. Clone and Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd CheckPointExam

# Run setup script
./scripts/setup.sh
```

### 2. Configure AWS

```bash
# Configure AWS credentials
aws configure

# Create S3 bucket for Terraform state
aws s3 mb s3://your-terraform-state-bucket --region us-west-1
```

### 3. Configure Terraform

Edit `terraform/backend.tf`:
```hcl
bucket = "your-terraform-state-bucket"
```

Edit `terraform/environments/prod/terraform.tfvars`:
```hcl
aws_region = "us-west-1"
environment = "prod"
project_name = "devops-exam"
api_token = "your-secure-token-here"
```

### 4. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 5. Build and Push Images

```bash
# Get ECR login
aws ecr get-login-password --region us-west-1 | \
  docker login --username AWS --password-stdin \
  $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-west-1.amazonaws.com

# Get repository URLs from Terraform
API_REPO=$(terraform output -raw ecr_api_repository_url)
SQS_REPO=$(terraform output -raw ecr_sqs_consumer_repository_url)

# Build and push API service
cd ../microservices/api-service
docker build -t api-service .
docker tag api-service:latest $API_REPO:latest
docker push $API_REPO:latest

# Build and push SQS consumer
cd ../sqs-consumer
docker build -t sqs-consumer .
docker tag sqs-consumer:latest $SQS_REPO:latest
docker push $SQS_REPO:latest
```

### 6. Test the API

```bash
# Get ALB endpoint
ALB_ENDPOINT=$(cd ../../terraform && terraform output -raw alb_dns_name)

# Get token from SSM
TOKEN=$(aws ssm get-parameter \
  --name /devops-exam/prod/api/token \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text)

# Test API
curl -X POST http://$ALB_ENDPOINT/api/email \
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

### 7. Verify S3 Upload

```bash
# Check S3 bucket
BUCKET=$(cd terraform && terraform output -raw s3_bucket_name)
aws s3 ls s3://$BUCKET/emails/ --recursive
```

## Using GitHub Actions (Recommended)

1. **Push to GitHub**
   ```bash
   git add .
   git commit -m "Initial commit"
   git push origin main
   ```

2. **Configure GitHub Secrets**:
   - Go to Settings > Secrets and variables > Actions
   - Add:
     - `AWS_ACCESS_KEY_ID`
     - `AWS_SECRET_ACCESS_KEY`
     - `AWS_REGION` (optional, defaults to us-west-1)

3. **CI/CD will automatically**:
   - Run tests
   - Build Docker images
   - Push to ECR
   - Deploy to ECS

## Common Issues

### Issue: Terraform backend error
**Solution**: Make sure S3 bucket exists and you have permissions

### Issue: ECS service not starting
**Solution**: Check CloudWatch logs and verify IAM roles

### Issue: API returns 401
**Solution**: Verify token in SSM matches the one you're using

### Issue: SQS consumer not processing
**Solution**: Check CloudWatch logs and verify SQS/S3 permissions

## Next Steps

- Review [ARCHITECTURE.md](ARCHITECTURE.md) for system design
- Review [DEPLOYMENT.md](DEPLOYMENT.md) for detailed deployment steps
- Review [README.md](README.md) for complete documentation

## Support

For issues or questions, check:
1. CloudWatch Logs
2. ECS Service Events
3. Terraform outputs
4. GitHub Actions logs

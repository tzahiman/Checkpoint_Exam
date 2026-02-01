#!/bin/bash

# Setup script for DevOps Exam Project
# This script helps set up the development environment

set -e

echo "🚀 Setting up DevOps Exam Project..."

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform >= 1.0"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install AWS CLI"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker"
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.9+"
    exit 1
fi

echo "✅ All prerequisites met"

# Create Python virtual environments
echo "🐍 Setting up Python virtual environments..."

if [ ! -d "microservices/api-service/venv" ]; then
    echo "Creating virtual environment for API service..."
    cd microservices/api-service
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    pip install -r tests/requirements.txt
    deactivate
    cd ../..
fi

if [ ! -d "microservices/sqs-consumer/venv" ]; then
    echo "Creating virtual environment for SQS consumer..."
    cd microservices/sqs-consumer
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    pip install -r tests/requirements.txt
    deactivate
    cd ../..
fi

echo "✅ Python environments set up"

# Create terraform.tfvars from example if it doesn't exist
if [ ! -f "terraform/environments/prod/terraform.tfvars" ]; then
    echo "📝 Creating terraform.tfvars from example..."
    cp terraform/environments/prod/terraform.tfvars.example terraform/environments/prod/terraform.tfvars
    echo "⚠️  Please edit terraform/environments/prod/terraform.tfvars with your configuration"
fi

# Initialize Terraform (only if S3 backend is bootstrapped)
echo "🏗️  Terraform..."
cd terraform
if [ -f "backend.s3.tfvars" ]; then
    echo "Initializing Terraform with S3 backend..."
    terraform init -reconfigure -backend-config=backend.s3.tfvars
else
    echo "⚠️  backend.s3.tfvars not found. Run from repo root: ./scripts/bootstrap-backend.sh"
    echo "    (Requires: aws configure)"
fi
cd ..

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Configure AWS: aws configure"
echo "2. Bootstrap S3 backend (one-time): ./scripts/bootstrap-backend.sh"
echo "3. Init Terraform: cd terraform && terraform init -reconfigure -backend-config=backend.s3.tfvars"
echo "4. Edit terraform/environments/prod/terraform.tfvars if needed"
echo "5. Plan/Apply: terraform plan -var-file=environments/prod/terraform.tfvars && terraform apply -var-file=environments/prod/terraform.tfvars"
echo "6. Build and push Docker images to ECR; deploy to ECS"

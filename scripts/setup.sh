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

# Initialize Terraform
echo "🏗️  Initializing Terraform..."
cd terraform
terraform init
cd ..

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit terraform/environments/prod/terraform.tfvars with your configuration"
echo "2. Update terraform/backend.tf with your S3 bucket for state"
echo "3. Configure AWS credentials: aws configure"
echo "4. Deploy infrastructure: cd terraform && terraform apply"
echo "5. Build and push Docker images to ECR"
echo "6. Deploy services to ECS"

# ECR Repository for API Service
resource "aws_ecr_repository" "api_service" {
  name                 = "${var.project_name}-api-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${var.project_name}-api-service"
    Environment = var.environment
  }
}

# ECR Repository for SQS Consumer
resource "aws_ecr_repository" "sqs_consumer" {
  name                 = "${var.project_name}-sqs-consumer"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${var.project_name}-sqs-consumer"
    Environment = var.environment
  }
}

# ECR Lifecycle Policy for API Service
resource "aws_ecr_lifecycle_policy" "api_service" {
  repository = aws_ecr_repository.api_service.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# ECR Lifecycle Policy for SQS Consumer
resource "aws_ecr_lifecycle_policy" "sqs_consumer" {
  repository = aws_ecr_repository.sqs_consumer.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

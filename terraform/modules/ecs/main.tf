# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "api_service" {
  name              = "/ecs/${var.project_name}/api-service"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-api-service-logs"
  }
}

resource "aws_cloudwatch_log_group" "sqs_consumer" {
  name              = "/ecs/${var.project_name}/sqs-consumer"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-sqs-consumer-logs"
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.project_name}-ecs-task-execution-role"
  }
}

# IAM Policy for ECS Task Execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Policy for SSM Parameter Access
resource "aws_iam_role_policy" "ssm_access" {
  name = "${var.project_name}-ssm-access"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ]
      Resource = [
        var.ssm_token_parameter_arn
      ]
    }]
  })
}

# IAM Role for ECS Task (API Service)
resource "aws_iam_role" "ecs_task_api" {
  name = "${var.project_name}-ecs-task-api-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.project_name}-ecs-task-api-role"
  }
}

# IAM Policy for API Service (SQS Publish)
resource "aws_iam_role_policy" "api_service_sqs" {
  name = "${var.project_name}-api-service-sqs"
  role = aws_iam_role.ecs_task_api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:SendMessage",
        "sqs:GetQueueAttributes"
      ]
      Resource = var.sqs_queue_arn
    }]
  })
}

# IAM Role for ECS Task (SQS Consumer)
resource "aws_iam_role" "ecs_task_sqs_consumer" {
  name = "${var.project_name}-ecs-task-sqs-consumer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.project_name}-ecs-task-sqs-consumer-role"
  }
}

# IAM Policy for SQS Consumer (SQS Receive, S3 Put)
resource "aws_iam_role_policy" "sqs_consumer_access" {
  name = "${var.project_name}-sqs-consumer-access"
  role = aws_iam_role.ecs_task_sqs_consumer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = var.sqs_queue_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${var.s3_bucket_arn}/*"
      }
    ]
  })
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    description     = "API Service from ALB"
    from_port       = var.api_service_port
    to_port         = var.api_service_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-tasks-sg"
  }
}

# ECS Task Definition - API Service
resource "aws_ecs_task_definition" "api_service" {
  family                   = "${var.project_name}-api-service"
  network_mode             = "awsvpc"
  requires_compatibilities  = ["FARGATE"]
  cpu                      = var.api_service_cpu
  memory                   = var.api_service_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_api.arn

  container_definitions = jsonencode([{
    name  = "api-service"
    image = "${var.ecr_repository_api}:latest"

    portMappings = [{
      containerPort = var.api_service_port
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "ENVIRONMENT"
        value = var.environment
      },
      {
        name  = "SQS_QUEUE_URL"
        value = var.sqs_queue_url
      },
      {
        name  = "SSM_TOKEN_PARAMETER"
        value = var.ssm_token_parameter_name
      },
      {
        name  = "AWS_REGION"
        value = var.aws_region
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.api_service.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:${var.api_service_port}/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])

  tags = {
    Name = "${var.project_name}-api-service"
  }
}

# ECS Task Definition - SQS Consumer
resource "aws_ecs_task_definition" "sqs_consumer" {
  family                   = "${var.project_name}-sqs-consumer"
  network_mode             = "awsvpc"
  requires_compatibilities  = ["FARGATE"]
  cpu                      = var.sqs_consumer_cpu
  memory                   = var.sqs_consumer_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_sqs_consumer.arn

  container_definitions = jsonencode([{
    name  = "sqs-consumer"
    image = "${var.ecr_repository_sqs_consumer}:latest"

    environment = [
      {
        name  = "ENVIRONMENT"
        value = var.environment
      },
      {
        name  = "SQS_QUEUE_URL"
        value = var.sqs_queue_url
      },
      {
        name  = "S3_BUCKET_NAME"
        value = var.s3_bucket_name
      },
      {
        name  = "SQS_POLL_INTERVAL"
        value = tostring(var.sqs_poll_interval)
      },
      {
        name  = "AWS_REGION"
        value = var.aws_region
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.sqs_consumer.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Name = "${var.project_name}-sqs-consumer"
  }
}

# ECS Service - API Service
resource "aws_ecs_service" "api_service" {
  name            = "${var.project_name}-api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api_service.arn
  desired_count   = var.api_service_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "api-service"
    container_port   = var.api_service_port
  }

  depends_on = [var.target_group_arn]

  tags = {
    Name = "${var.project_name}-api-service"
  }
}

# ECS Service - SQS Consumer
resource "aws_ecs_service" "sqs_consumer" {
  name            = "${var.project_name}-sqs-consumer"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sqs_consumer.arn
  desired_count   = var.sqs_consumer_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  tags = {
    Name = "${var.project_name}-sqs-consumer"
  }
}

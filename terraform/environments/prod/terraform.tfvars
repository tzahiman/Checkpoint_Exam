aws_region = "us-west-1"
environment = "prod"
project_name = "tzahi-devops-exam"

# ECS Configuration
api_service_cpu = 256
api_service_memory = 512
sqs_consumer_cpu = 256
sqs_consumer_memory = 512

# Application Configuration
api_service_port = 8000
sqs_poll_interval = 30

# API auth: after deploy, set SSM parameter value via AWS Console or CLI (no tokens in code)

# Monitoring
enable_monitoring = true

# Get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  availability_zones   = data.aws_availability_zones.available.names
}

# S3 Module
module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
}

# SQS Module
module "sqs" {
  source = "./modules/sqs"

  project_name = var.project_name
  environment  = var.environment
}

# SSM Module
module "ssm" {
  source = "./modules/ssm"

  project_name = var.project_name
  environment  = var.environment
  api_token    = var.api_token
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment
}

# ALB Module
module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  api_service_port  = var.api_service_port
}

# ECS Module
module "ecs" {
  source = "./modules/ecs"

  project_name                = var.project_name
  environment                 = var.environment
  aws_region                  = var.aws_region
  vpc_id                      = module.vpc.vpc_id
  private_subnet_ids          = module.vpc.private_subnet_ids
  alb_security_group_id       = module.alb.alb_security_group_id
  target_group_arn            = module.alb.target_group_arn
  api_service_cpu             = var.api_service_cpu
  api_service_memory          = var.api_service_memory
  sqs_consumer_cpu            = var.sqs_consumer_cpu
  sqs_consumer_memory         = var.sqs_consumer_memory
  api_service_port            = var.api_service_port
  sqs_poll_interval           = var.sqs_poll_interval
  ecr_repository_api          = module.ecr.api_service_repository_url
  ecr_repository_sqs_consumer = module.ecr.sqs_consumer_repository_url
  sqs_queue_url               = module.sqs.queue_url
  sqs_queue_arn               = module.sqs.queue_arn
  s3_bucket_name              = module.s3.bucket_name
  s3_bucket_arn               = module.s3.bucket_arn
  ssm_token_parameter_name    = module.ssm.api_token_parameter_name
  ssm_token_parameter_arn     = module.ssm.api_token_parameter_arn
  enable_container_insights   = var.enable_monitoring
}

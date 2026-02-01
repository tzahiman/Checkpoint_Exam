# SSM Parameter for API Token
resource "aws_ssm_parameter" "api_token" {
  name        = "/${var.project_name}/${var.environment}/api/token"
  description = "API authentication token"
  type        = "SecureString"
  value       = var.api_token

  tags = {
    Name        = "${var.project_name}-api-token"
    Environment = var.environment
  }
}

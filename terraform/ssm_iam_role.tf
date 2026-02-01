
# IAM Policy for API Service Task Role - SSM Parameter Access
resource "aws_iam_role_policy" "api_service_ssm_access" {
  name = "${var.project_name}-api-service-ssm-access"
  role = module.ecs.api_service_task_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = module.ssm.api_token_parameter_arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" : "ssm.${var.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

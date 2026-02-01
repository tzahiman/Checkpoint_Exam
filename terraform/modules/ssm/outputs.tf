output "api_token_parameter_name" {
  description = "SSM parameter name for API token"
  value       = aws_ssm_parameter.api_token.name
  sensitive   = false
}

output "api_token_parameter_arn" {
  description = "SSM parameter ARN for API token"
  value       = aws_ssm_parameter.api_token.arn
}

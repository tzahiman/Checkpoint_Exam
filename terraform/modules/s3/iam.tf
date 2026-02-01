resource "aws_iam_policy" "s3_public_access" {
  name        = "${var.project_name}-${var.environment}-s3-public-access-policy"
  description = "Policy to allow S3 PutPublicAccessBlock action"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:PutBucketPublicAccessBlock"
        Resource = "arn:aws:s3:::${var.project_name}-${var.environment}-email-storage"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "s3_public_access_attachment" {
  user       = var.iam_user_name
  policy_arn = aws_iam_policy.s3_public_access.arn
}
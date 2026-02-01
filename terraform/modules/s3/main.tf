# S3 Bucket for email storage
resource "aws_s3_bucket" "main" {
  bucket = "${var.project_name}-${var.environment}-email-storage"
}

# S3 Bucket Public Access Block
# resource "aws_s3_bucket_public_access_block" "main" {
#   bucket = aws_s3_bucket.main.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }
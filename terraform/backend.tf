# S3 backend - run scripts/bootstrap-backend.sh once to create bucket + DynamoDB table,
# then: terraform init -reconfigure -backend-config=backend.s3.tfvars
terraform {
  backend "s3" {
    # bucket, key, region, dynamodb_table, encrypt supplied via -backend-config=backend.s3.tfvars
  }
}

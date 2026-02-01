# S3 backend configuration - inline values from backend.s3.tfvars
# No longer requires -backend-config flag when running terraform init
terraform {
  backend "s3" {
    bucket         = "devops-exam-terraform-state-371670420772"
    key            = "devops-exam/terraform.tfstate"
    region         = "us-west-1"
    encrypt        = true
    dynamodb_table = "devops-exam-terraform-lock"
  }
}

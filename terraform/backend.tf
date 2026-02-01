terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket" # Update this
    key            = "devops-exam/terraform.tfstate"
    region         = "us-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock" # Optional: for state locking
  }
}

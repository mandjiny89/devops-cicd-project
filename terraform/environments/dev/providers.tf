provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "devops-cicd-project"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

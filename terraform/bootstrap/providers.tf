provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "devops-cicd-project"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

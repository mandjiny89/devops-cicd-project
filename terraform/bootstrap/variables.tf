variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "mandjiny89"
}

variable "github_repository" {
  description = "GitHub repository name"
  type        = string
  default     = "devops-cicd-project"
}

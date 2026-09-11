variable "aws_region" {
  description = "AWS region used for the development environment."
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

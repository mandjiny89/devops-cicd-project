output "aws_region" {
  description = "AWS region configured for this environment."
  value       = var.aws_region
}

output "environment" {
  description = "Current Terraform environment."
  value       = var.environment
}

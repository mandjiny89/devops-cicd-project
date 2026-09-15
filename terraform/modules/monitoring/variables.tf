variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alert_email" {
  description = "Email address used for monitoring alerts"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix used for CloudWatch metrics"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target Group ARN suffix used for CloudWatch metrics"
  type        = string
}

variable "asg_name" {
  description = "Auto Scaling Group name"
  type        = string
}
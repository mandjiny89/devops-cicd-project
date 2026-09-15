output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix used by CloudWatch ALB metrics"
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  description = "ARN suffix used by CloudWatch target group metrics"
  value       = aws_lb_target_group.app.arn_suffix
}
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name        = "${var.project_name}-${var.environment}-alb-5xx"
  alarm_description = "ALB is returning HTTP 5xx errors"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"
  statistic   = "Sum"

  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  treat_missing_data = "notBreaching"

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name        = "${var.project_name}-${var.environment}-unhealthy-targets"
  alarm_description = "One or more ALB targets are unhealthy"

  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"
  statistic   = "Maximum"

  period             = 60
  evaluation_periods = 2

  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  treat_missing_data = "notBreaching"

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name        = "${var.project_name}-${var.environment}-high-cpu"
  alarm_description = "Average CPU utilisation for the ASG is high"

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"
  statistic   = "Average"

  period             = 300
  evaluation_periods = 2

  threshold           = 80
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  treat_missing_data = "notBreaching"

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]
}


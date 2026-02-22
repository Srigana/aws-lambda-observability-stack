resource "aws_sns_topic" "critical_alerts" {
  name         = "${var.project_name}-${var.environment}-critical-alerts"
  display_name = "Critical Lambda Alerts - ${var.project_name}"

  tags = merge(
    var.tags, {
      Name      = "${var.project_name}-${var.environment}-critical-alerts"
      AlertType = "Critical"
    }
  )
}

resource "aws_sns_topic" "performance_alerts" {
  name         = "${var.project_name}-${var.environment}-performance-alerts"
  display_name = "Performance Alerts - ${var.project_name}"

  tags = merge(
    var.tags, {
      Name      = "${var.project_name}-${var.environment}-performance-alerts"
      AlertType = "Performance"
    }
  )
}

resource "aws_sns_topic" "log_alerts" {
  name         = "${var.project_name}-${var.environment}-log-alerts"
  display_name = "Log Alerts - ${var.project_name}"

  tags = merge(
    var.tags, {
      Name      = "${var.project_name}-${var.environment}-Log-alerts"
      AlertType = "Logs"
    }
  )
}

resource "aws_sns_topic_subscription" "critical_email" {
  count     = var.critical_alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "email"
  endpoint  = var.critical_alert_email
}

resource "aws_sns_topic_subscription" "performance_email" {
  count     = var.performance_alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.performance_alerts.arn
  protocol  = "email"
  endpoint  = var.performance_alert_email
}

resource "aws_sns_topic_subscription" "log_email" {
  count     = var.log_alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.log_alerts.arn
  protocol  = "email"
  endpoint  = var.log_alert_email
}

resource "aws_sns_topic_policy" "critical_alerts_policy" {
  arn = aws_sns_topic.critical_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.critical_alerts.arn
      }
    ]
  })
}

resource "aws_sns_topic_policy" "performance_alerts_policy" {
  arn = aws_sns_topic.performance_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.performance_alerts.arn
      }
    ]
  })
}

resource "aws_sns_topic_policy" "log_alerts_policy" {
  arn = aws_sns_topic.log_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.log_alerts.arn
      }
    ]
  })
}
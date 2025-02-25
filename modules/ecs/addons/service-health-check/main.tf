# --------------------------------------------------------------
# Create CloudWatch Alarm to monitor ECS service's ALB health check
# --------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "alb_health_check_failed" {
  alarm_name          = "${var.service_name}-health-check-failed"
  comparison_operator = "LessThanThreshold" # trigger alarm when healthy host count is less than 1
  evaluation_periods  = 3
  metric_name         = "HealthyHostCount" # metric name from ALB
  namespace           = "AWS/ApplicationELB"
  period              = 60 # seconds
  statistic           = "Average"
  threshold           = 1 # healthy host count
  alarm_description   = "Triggered when ALB health check fails for ECS service ${var.service_name}"
  dimensions = {
    LoadBalancer = var.alb_name
    TargetGroup  = var.target_group_name
  }

  actions_enabled = true
  alarm_actions   = [aws_sns_topic.slack_notifications.arn]
}

# ------------------------------------------------------------------------
# CREATE SNS Topic that will publish messages
# ------------------------------------------------------------------------

resource "aws_sns_topic" "slack_notifications" {
  name = "${var.service_name}-slack-notifications"
}

resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.slack_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier.arn
}

# ------------------------------------------------------------------------
# CREATE LAMBDA FUNCTION
# ------------------------------------------------------------------------

# TODO: add package step to create zip file, check out other repo in github

resource "aws_lambda_function" "slack_notifier" {
  filename         = "slack_notifier.zip"
  function_name    = "${var.service_name}-slack-notifier"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "slack_notifier.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("slack_notifier.zip")

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }

  depends_on = [aws_lambda_permission.sns_invoke]
}

resource "aws_lambda_permission" "sns_invoke" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.slack_notifications.arn
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${var.service_name}-lambda-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "sns_publish_policy" {
  name   = "sns-publish-policy"
  role   = aws_iam_role.lambda_exec.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "sns:Publish"
      Effect   = "Allow"
      Resource = aws_sns_topic.slack_notifications.arn
    }]
  })
}

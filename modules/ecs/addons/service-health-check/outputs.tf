output "sns_topic_arn" {
  description = "ARN of the created SNS topic"
  value       = aws_sns_topic.slack_notifications.arn
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.slack_notifier.arn
}

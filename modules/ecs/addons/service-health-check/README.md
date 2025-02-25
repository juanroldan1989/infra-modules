# service-health-check-notifier

This module sets up an ECS service health check notifier. It creates:

1. An SNS topic to capture health check failures.
2. A Lambda function that sends alerts to a specified Slack channel via a webhook.
3. Subscriptions and permissions required for the integration.

## How it works

1. The CloudWatch Alarm triggers when the ALB health check fails.
2. The SNS Topic forwards the alarm to the Lambda function.
3. The Lambda function sends a formatted message to Slack using an Incoming Webhook.

## Variables

- `slack_webhook_url`: The Slack webhook URL to receive notifications.

## Outputs

- `sns_topic_arn`: The ARN of the created SNS topic.
- `lambda_function_arn`: The ARN of the Lambda function.

## Terragrunt Configuration Example

For each environment (staging, production), you can reference the module using Terragrunt:

### **`environments/prod/service-a-health-check/terragrunt.hcl`**

```hcl
terraform {
  source = "../../modules/service-health-check-notifier"
}

inputs = {
  service_name = "service-a"
  alb_name = "service-a-alb"
  target_group_name = "service-a-target-group"
  slack_webhook_url = "https://hooks.slack.com/services/your/webhook/url"
}
```

## Diagram

```bash
+-------------------------------------+
|        CloudWatch Alarm             |
|  (aws_cloudwatch_metric_alarm)      |
+-------------------------------------+
                |
                v
+-------------------------------------+
|        SNS Topic                    |
| (aws_sns_topic.slack_notifications) |-----------------------+
+-------------------------------------+                       |
                |                                             |
                |                                             |
                v                                             v
+-------------------------------------+       +-------------------------------------+
|    SNS Topic Subscription           |       |    Lambda Permission for SNS Invoke |
| (aws_sns_topic_subscription.lambda_ |       |      (aws_lambda_permission.sns_    |
|        subscription)                |       |              invoke)                |
+-------------------------------------+       +-------------------------------------+
                |                                             |
                v                                             |
+-------------------------------------+                       |
|        Lambda Function              | <---------------------+
| (aws_lambda_function.slack_notifier)|
+-------------------------------------+
                |
                v
+-------------------------------------+
|     IAM Role for Lambda Execution   |
|      (aws_iam_role.lambda_exec)     |
+-------------------------------------+
```

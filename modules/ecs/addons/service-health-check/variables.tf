variable "service_name" {
  description = "The name of the ECS service"
  type        = string
}

variable "alb_name" {
  description = "The name of the ALB"
  type        = string
}

variable "target_group_name" {
  description = "The name of the target group"
  type        = string
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
}

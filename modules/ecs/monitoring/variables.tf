# ------------------------------------------------------------------------
# VARIABLES DEFINED BASED ON ENVIRONMENT
# ------------------------------------------------------------------------

variable "aws_account_id" {
  description = "The AWS account ID"
  type        = string
}

variable "aws_region" {
  description = "The AWS region"
  type        = string
}

variable "env" {
  description = "The environment"
  type        = string
}

# ------------------------------------------------------------------------
# NETWORKING VARIABLES
# ------------------------------------------------------------------------

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "The IDs of the private subnets for ECS tasks"
  type        = list(string)
}

variable "alb_subnet_ids" {
  description = "The IDs of the public subnets for ALB (internet-facing)"
  type        = list(string)
}

variable "ecs_cluster_id" {
  description = "The ID of the ECS cluster"
  type        = string
}

# ------------------------------------------------------------------------
# GRAFANA CONFIGURATION
# ------------------------------------------------------------------------

variable "grafana_image" {
  description = "Grafana Docker image"
  type        = string
  default     = "grafana/grafana:latest"
}

variable "grafana_task_cpu" {
  description = "CPU units for Grafana task"
  type        = string
  default     = "512"
}

variable "grafana_task_memory" {
  description = "Memory for Grafana task"
  type        = string
  default     = "1024"
}

variable "grafana_container_cpu" {
  description = "CPU units for Grafana container"
  type        = number
  default     = 256
}

variable "grafana_container_memory" {
  description = "Memory for Grafana container"
  type        = number
  default     = 512
}

variable "grafana_desired_count" {
  description = "Desired number of Grafana tasks"
  type        = number
  default     = 1
}

variable "grafana_admin_user" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "grafana_domain" {
  description = "Domain name for Grafana"
  type        = string
}

variable "grafana_allowed_cidrs" {
  description = "CIDR blocks allowed to access Grafana"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

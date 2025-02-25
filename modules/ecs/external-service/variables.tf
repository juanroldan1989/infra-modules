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
# ECS SERVICE VARIABLES
# ------------------------------------------------------------------------

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "The IDs of the subnets"
  type        = list(string)
}

variable "ecs_cluster_id" {
  description = "The ID of the ECS cluster"
  type        = string
}

variable "service_name" {
  description = "The name of the ECS service"
  type        = string
  default     = "ecs-service"
}

variable "desired_count" {
  description = "The desired number of tasks"
  type        = number
  default     = 1
}

variable "launch_type" {
  description = "The launch type"
  type        = string
  default     = "FARGATE"
}

variable "container_name" {
  description = "The name of the container"
  type        = string
  default     = "sample-app"
}

variable "container_port" {
  description = "The port of the container"
  type        = number
  default     = 80
}

variable "alb_port" {
  description = "The port ALB listens on"
  type        = number
  default     = 80
}

# ------------------------------------------------------------------------
# ECS TASK VARIABLES
# ------------------------------------------------------------------------

variable "task_cpu" {
  description = "The number of CPU units to reserve for the container"
  type        = string
  default     = "512"
}

variable "task_memory" {
  description = "The amount of memory (in MiB) to reserve for the container"
  type        = string
  default     = "1024"
}

variable "requires_compatibilities" {
  description = "The launch type compatibility requirement for the task"
  type        = list(string)
  default     = ["FARGATE"]
}

variable "network_mode" {
  description = "The network mode to use for the task"
  type        = string
  default     = "awsvpc"
}

variable "env_vars" {
  description = "The environment variables to pass to the container"
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------------------
# ECS TASK TEMPLATE VARIABLES
# ------------------------------------------------------------------------

variable "app_name" {
  description = "The name of the application"
  type        = string
  default     = "sample-app"
}

variable "app_image" {
  description = "The Docker image of the application"
  type        = string
  default     = "public.ecr.aws/nginx/nginx:1.27.1-alpine3.20-perl"
}

variable "container_cpu" {
  description = "The number of CPU units to reserve for the container"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "The amount of memory (in MiB) to reserve for the container"
  type        = number
  default     = 256
}

variable "essential" {
  description = "If the task is essential"
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------
# ECS HEALTHCHECK VARIABLES
# ------------------------------------------------------------------------

variable "health_check_path" {
  description = "Path to use for the ALB health check"
  type        = string
  default     = "/"
}

variable "health_check_interval" {
  description = "Time (in seconds) between each health check"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Time (in seconds) before the health check times out"
  type        = number
  default     = 5
}

variable "healthy_threshold" {
  description = "Number of consecutive successful health checks required before considering the target healthy"
  type        = number
  default     = 3
}

variable "unhealthy_threshold" {
  description = "Number of consecutive failed health checks required before considering the target unhealthy"
  type        = number
  default     = 2
}

variable "health_check_matcher" {
  description = "HTTP status code to match for a healthy target"
  type        = string
  default     = "200"
}

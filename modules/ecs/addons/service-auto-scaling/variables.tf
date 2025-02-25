variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "The name of the ECS service"
  type        = string
  default     = "ecs-service"
}

variable "ecs_auto_scale_role_name" {
  description = "The name of the ECS auto scale role"
  type        = string
  default     = "ecs-auto-scale-role"
}

variable "min_capacity" {
  description = "The minimum capacity of the ECS service"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "The maximum capacity of the ECS service"
  type        = number
  default     = 6
}

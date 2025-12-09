# ------------------------------------------------------------------------
# VARIABLES DEFINED BASED ON ENVIRONMENT
# ------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region"
  type        = string
}

variable "env" {
  description = "The environment"
  type        = string
}

# ------------------------------------------------------------------------
# ECS CLUSTER VARIABLES
# ------------------------------------------------------------------------

variable "cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

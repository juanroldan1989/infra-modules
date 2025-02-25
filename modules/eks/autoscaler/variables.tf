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
# VARIABLES FOR EKS CLUSTER AUTOSCALER
# ------------------------------------------------------------------------

variable "eks_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "metrics_server" {}

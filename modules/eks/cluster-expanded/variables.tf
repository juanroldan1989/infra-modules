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
# VARIABLES FOR EKS CLUSTER
# ------------------------------------------------------------------------

variable "eks_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "eks_version" {
  type    = string
  default = "1.30"
}

variable "private_subnets" {
  type = list(string)
}

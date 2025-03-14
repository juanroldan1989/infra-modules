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
  description = "The ID of the VPC."
  type        = string
}

variable "subnet_ids" {
  description = "The IDs of the private subnets."
  type        = list(string)
}

variable "control_plane_subnet_ids" {
  description = "The IDs of the subnets for the control plane."
  type        = list(string)
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

# ------------------------------------------------------------------------
# VARIABLES DEFINED BASED ON ENVIRONMENT
# ------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region"
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
  description = "The IDs of the subnets."
  type        = list(string)
}

variable "control_plane_subnet_ids" {
  description = "The IDs of the subnets for the control plane."
  type        = list(string)
}

# ------------------------------------------------------------------------
# EKS VARIABLES
# ------------------------------------------------------------------------

variable "eks_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "use_local_kubeconfig" {
  description = "If true, use local (~/.kube/config) file for authentication. If false, use token-based EKS access (e.g. for CI)."
  type        = bool
  default     = true
}

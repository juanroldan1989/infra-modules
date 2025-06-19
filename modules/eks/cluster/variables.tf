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
  default = "1.32" # End Of Standard Support: 21/03/2026 / End Of Extended Support: 21/03/2027
}

variable "instance_types" {
  description = "The instance types for the EKS managed node groups."
  type        = list(string)
  default     = ["t3.medium"] # Minimum for ArgoCD + ESO + ALB Controller + Prometheus + Grafana
}

variable "public_cidrs" {
  description = "The CIDRs that are allowed to access the EKS cluster endpoint."
  type        = list(string)
  default     = []
}

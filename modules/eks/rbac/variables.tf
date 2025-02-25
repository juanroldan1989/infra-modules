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

variable "namespace" {
  description = "The Kubernetes namespace to which developers will have access."
  default     = "dev-apps"
}

# ------------------------------------------------------------------------
# VARIABLES FOR RBAC
# ------------------------------------------------------------------------
variable "developer_iam_users" {
  description = "The IAM users who are allowed to assume the developer role."
  type        = list(string)
}

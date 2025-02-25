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

variable "zone1" {
  type    = string
  default = "us-east-1a"
}

variable "zone2" {
  type    = string
  default = "us-east-1b"
}

variable "eks_name" {
  type    = string
  default = "sample-eks"
}

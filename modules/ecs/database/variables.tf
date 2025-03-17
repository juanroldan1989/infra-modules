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

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

# ------------------------------------------------------------------------
# VARIABLES FOR DATABASE MODULE
# ------------------------------------------------------------------------

variable "allocated_storage" {
  description = "The allocated storage in gigabytes."
  type        = number
  default     = 20
}

variable "engine" {
  description = "The database engine to use."
  type        = string
  default     = "mysql"
}

variable "engine_version" {
  description = "The version of the database engine to use."
  type        = string
  default     = "5.7"
}

variable "instance_class" {
  description = "The instance class to use."
  type        = string
  default     = "db.t3.micro"
}

variable "app_name" {
  description = "The name of the application."
  type        = string
}

variable "db_username" {
  description = "The username for the database."
  type        = string
}

variable "db_password" {
  description = "The password for the database."
  type        = string
}

variable "parameter_group_name" {
  description = "The name of the parameter group to use."
  type        = string
  default     = "default.mysql5.7"
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot."
  type        = bool
  default     = true
}

variable "publicly_accessible" {
  description = "Whether the RDS instance is publicly accessible."
  type        = bool
  default     = false
}

variable "storage_type" {
  description = "The storage type to use."
  type        = string
  default     = "gp2"
}

variable "storage_encrypted" {
  description = "Whether the storage is encrypted."
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Whether the RDS instance is multi-AZ."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "The backup retention period in days."
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "The backup window."
  type        = string
  default     = "02:00-03:00" # UTC
}

variable "maintenance_window" {
  description = "The maintenance window."
  type        = string
  default     = "sun:05:00-sun:06:00" # UTC
}

variable "db_port" {
  description = "The port for the database."
  type        = number
  default     = 3306
}

# ------------------------------------------------------------------------
# VARIABLES FOR DB SUBNET GROUP
# ------------------------------------------------------------------------

variable "private_subnets" {
  type = list(string)
}

# ------------------------------------------------------------------------
# VARIABLES FOR DB SECURITY GROUP
# ------------------------------------------------------------------------
# This security group allows access from the ECS service.

variable "ecs_task_sg_id" {
  type = string
}

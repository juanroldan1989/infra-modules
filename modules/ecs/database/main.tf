# ------------------------------------------------------------------------
# CREATE RDS INSTANCE
# ------------------------------------------------------------------------

locals {
  db_instance_tags = {
    Name        = "${var.env}-${var.aws_region}-${var.app_name}-rds"
    Application = var.app_name
    Service     = "RDS"
    Purpose     = "Database"
  }
}

resource "aws_db_instance" "main" {
  allocated_storage       = var.allocated_storage
  engine                  = var.engine
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  identifier              = "${var.env}-${var.aws_region}-${var.app_name}-rds"
  username                = var.db_username
  password                = var.db_password
  parameter_group_name    = var.parameter_group_name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  db_subnet_group_name    = aws_db_subnet_group.main.name
  skip_final_snapshot     = var.skip_final_snapshot
  publicly_accessible     = var.publicly_accessible
  storage_type            = var.storage_type
  storage_encrypted       = var.storage_encrypted
  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  tags                    = local.db_instance_tags
}

# ------------------------------------------------------------------------
# CREATE SECURITY GROUP FOR RDS INSTANCE
# ------------------------------------------------------------------------
# This security group allows access from the ECS service.

locals {
  sg_tags = {
    Name        = "${var.env}-${var.aws_region}-${var.app_name}-rds-sg"
    Application = var.app_name
    Service     = "RDS"
    Purpose     = "Security Group"
  }
}

resource "aws_security_group" "rds" {
  name   = "rds-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "Allow access from ECS Task"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ecs_task_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.sg_tags
}

# ------------------------------------------------------------------------
# CREATE SUBNET GROUP FOR RDS INSTANCE
# ------------------------------------------------------------------------
# This subnet group is used to place the RDS instance in the private subnets of the VPC.

resource "aws_db_subnet_group" "main" {
  name       = "${var.env}-${var.aws_region}-rds-subnet-group"
  subnet_ids = var.private_subnets
}

# ------------------------------------------------------------------------
# ECS TASK EXECUTION ROLE
# ------------------------------------------------------------------------
# This role allows the ECS task to assume the role and connect to the RDS instance.

resource "aws_iam_role" "ecs_task_execution" {
  name = "ecs_task_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ------------------------------------------------------------------------
# ECS TASK EXECUTION POLICY
# ------------------------------------------------------------------------
# This policy grants the ECS task permissions to connect to the RDS instance
# and retrieve the database credentials from AWS Secrets Manager.

resource "aws_iam_role_policy" "ecs_task_execution_policy" {
  name = "ecs-task-policy"
  role = aws_iam_role.ecs_task_execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect",
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.db_credentials.arn
        ]
      }
    ]
  })
}

# ------------------------------------------------------------------------
# SECRETS MANAGEMENT
# ------------------------------------------------------------------------
# This secret stores the database credentials.

locals {
  db_crendentials_secret_tags = {
    Name        = "${var.env}-${var.aws_region}-${var.app_name}-db-credentials"
    Application = var.app_name
    Service     = "RDS"
    Purpose     = "Database Credentials"
  }
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name = "db-credentials"
  tags = local.db_crendentials_secret_tags
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}

# ------------------------------------------------------------------------
# SECRETS USAGE WITHIN ECS TASK DEFINITION
# ------------------------------------------------------------------------

# TODO: apply the following changes to the ECS task definition in the ECS Service module:
# ...
# secrets   = [
#   {
#     name      = "DB_USERNAME"
#     valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:username"
#   },
#   {
#     name      = "DB_PASSWORD"
#     valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:password"
#   }
# ]
# ...

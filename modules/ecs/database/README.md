# Database Module for ECS Service

## Introduction

This Terraform module creates an Amazon RDS instance with all necessary configurations

to ensure secure and reliable database management for your application.

It includes associated resources such as a security group, subnet group, IAM roles for ECS task execution

and integration with AWS Secrets Manager for securely managing database credentials.

## Features

- Creates an RDS instance in a private subnet.
- Configures a security group to allow access only from an ECS task.
- Sets up a subnet group for private subnet placement of the RDS instance.
- Integrates with AWS Secrets Manager for secure storage of database credentials.
- Provides IAM roles and policies for ECS tasks to access RDS and Secrets Manager.

## Resources Created

This module creates the following AWS resources:

1. **RDS Instance (`aws_db_instance`)**:
   - Configurable for engine type, instance class, storage type, and other parameters.
2. **RDS Security Group (`aws_security_group`)**:
   - Allows traffic only from ECS tasks to the RDS instance.
3. **RDS Subnet Group (`aws_db_subnet_group`)**:
   - Ensures the RDS instance is deployed in private subnets.
4. **IAM Role and Policy for ECS Tasks (`aws_iam_role` & `aws_iam_role_policy`)**:
   - Grants ECS tasks permission to connect to RDS and retrieve credentials from Secrets Manager.
5. **Secrets Manager Secret and Version (`aws_secretsmanager_secret` & `aws_secretsmanager_secret_version`)**:
   - Stores the database credentials securely.

## Usage

Here is an example of how to use this module:

```bash
module "database" {
  source = "./path-to-module"

  env                     = "production"
  aws_region              = "eu-west-1"
  app_name                = "myapp"
  allocated_storage       = 20
  engine                  = "postgres"
  engine_version          = "13.4"
  instance_class          = "db.t3.micro"
  username                = "admin"
  password                = "securepassword"
  parameter_group_name    = "default.postgres13"
  vpc_id                  = "vpc-0123456789abcdef0"
  private_subnets         = ["subnet-1234abcd", "subnet-5678efgh"]
  ecs_task_sg_id          = "sg-ecs-task-id"
  skip_final_snapshot     = false
  publicly_accessible     = false
  storage_type            = "gp2"
  storage_encrypted       = true
  multi_az                = false
  backup_retention_period = 7
  backup_window           = "00:00-01:00"
  maintenance_window      = "Mon:01:00-Mon:02:00"
}
```

## Outputs

This module provides the following outputs:

- `rds_endpoint`: The endpoint of the RDS instance.
- `rds_security_group_id`: The ID of the security group associated with the RDS instance.
- `secretsmanager_secret_arn`: The ARN of the Secrets Manager secret storing database credentials.

## Dependencies

This module assumes the following dependencies are already provisioned:

1. A VPC with private subnets.
2. An ECS service with a security group (`ecs_task_sg_id`) that allows communication with the RDS instance.

## Diagram

```bash
+-----------------+       +--------------------+
|  ECS Task       | ----> |  RDS Security      |
|  (Application)  |       |  Group             |
+-----------------+       +--------------------+
       |                            |
       v                            v
+-----------------+       +--------------------+
|  Secrets Manager |      |  RDS Instance      |
|  (Credentials)   |      |  (PostgreSQL)      |
+-----------------+       +--------------------+
```

### Explanation

- `ECS Task`: Represents the containerized application requiring access to the database.
- `Secrets Manager`: Stores sensitive database credentials securely, accessible only by authorized ECS tasks.
- `RDS Security Group`: Restricts traffic to the database, allowing only ECS tasks to connect.
- `RDS Instance`: The PostgreSQL database hosted within a private subnet.

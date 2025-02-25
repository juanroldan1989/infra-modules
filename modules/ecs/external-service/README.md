# External Service: ECS Service with Load Balancer Terraform Module

This Terraform module creates an:

- ECS Service
- ECS Task
- ALB (Application Load Balancer)
- Security Groups and
- related resources to deploy and manage a containerized application in AWS ECS.

## Features

- Creates an ECS service with desired count and task definition.
- Configures an ECS Task Definition with container definitions.
- Sets up an Application Load Balancer (ALB) for the ECS service.
- Configures Security Groups for ALB and ECS tasks.
- Creates CloudWatch Log Groups and Log Streams for ECS task logging.
- Supports flexible network configuration with VPC subnets and security groups.
- Includes health checks for the ALB target group.

## Resources Created

1. **ECS Service** (`aws_ecs_service.main`)
2. **ECS Task Definition** (`aws_ecs_task_definition.app`)
3. **Security Groups**:
  - ALB Security Group (`aws_security_group.sg_alb`)
  - ECS Task Security Group (`aws_security_group.sg_ecs_task_alb`)
4. **Application Load Balancer (ALB)** (`aws_lb.alb_ecs`)
5. **ALB Listener** (`aws_lb_listener.alb_listener_http`)
6. **ALB Target Group** (`aws_lb_target_group.tg_alb_http`)
7. **CloudWatch Log Group** (`aws_cloudwatch_log_group.cb_log_group`)
8. **CloudWatch Log Stream** (`aws_cloudwatch_log_stream.cb_log_stream`)

## Usage

```hcl
...
dependency "networking" {
  config_path = "../networking"
}

dependency "ecs_cluster" {
  config_path = "../clusters/ecs-a"
}

inputs = {
  aws_account_id = local.aws_account_id
  aws_region     = local.aws_region
  env            = local.env
  vpc_id         = dependency.networking.outputs.vpc_id
  subnet_ids     = dependency.networking.outputs.subnet_ids
  ecs_cluster_id = dependency.ecs_cluster.outputs.cluster_id
  service_name   = "ecs-service-a"
}
```

## Outputs

- `service_name` - Name of the created service
- `service_url` -	DNS name of the Application Load Balancer
- `log_group_name` - Name of CloudWatch Log Group for ECS logs

## Dependencies

This module has the following dependencies:

- AWS ECS Cluster
- VPC and Subnets
- IAM Roles and Policies for ECS tasks and services

## Diagram

```bash
                                    +-----------------------------+
                                    |        AWS Internet         |
                                    +-----------------------------+
                                               |
                                               v
                                  +----------------------------+
                                  |        ALB (aws_lb)        |
                                  +----------------------------+
                                      |                  |
                         +--------------------+  +----------------------+
                         | ALB Listener (80)  |  | ALB Listener (443)   |
                         +--------------------+  +----------------------+
                                      |
                                      v
                        +-----------------------------+
                        | Target Group (tg_alb_http)  |
                        +-----------------------------+
                                      |
                                      v
                          +-------------------------+
                          | ECS Service (ecs_main)  |
                          +-------------------------+
                              |                |
                +------------------------+  +--------------------+
                | Subnets (var.subnet_ids)  | Security Group     |
                +------------------------+  +--------------------+
                                                      |
                                                      v
                                        +-----------------------------+
                                        | ECS Task Definition (app)   |
                                        |  - Container (app)          |
                                        |  - CPU: var.container_cpu   |
                                        |  - Memory: var.container_mem|
                                        |  - Port: var.container_port |
                                        +-----------------------------+
                                                      |
                                                      v
                                        +-------------------------+
                                        | CloudWatch Log Group    |
                                        +-------------------------+
                                                      |
                                        +-------------------------+
                                        | CloudWatch Log Stream   |
                                        +-------------------------+
```

Explanation:

1. AWS Internet: Represents incoming traffic from the internet.

2. ALB (Application Load Balancer): Handles HTTP/HTTPS requests and forwards them to the target group.

3. Target Group: Forwards traffic to the ECS service based on health checks.

4. ECS Service: Manages the ECS tasks and ensures the desired count is maintained.

5. ECS Task Definition: Defines the container (image, CPU, memory, port) and logging configuration.

6. Security Group: Controls inbound/outbound traffic for the ECS tasks.

7. Subnets: Ensures ECS tasks are deployed in the specified VPC subnets.

8. CloudWatch Logs: Captures container logs for monitoring.

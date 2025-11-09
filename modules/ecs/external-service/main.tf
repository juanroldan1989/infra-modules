# ------------------------------------------------------------------------
# CREATE ECS SERVICE
# ------------------------------------------------------------------------

locals {
  service_tags = {
    Name        = "${var.env}-${var.aws_region}-${var.app_name}-ecs-service"
    Application = var.app_name
    Service     = "ECS"
    Purpose     = "Application Service Definition"
  }
}

resource "aws_ecs_service" "main" {
  name                 = var.service_name
  cluster              = var.ecs_cluster_id
  task_definition      = aws_ecs_task_definition.app.arn
  desired_count        = var.desired_count
  launch_type          = var.launch_type
  force_new_deployment = true
  tags                 = local.service_tags

  network_configuration {
    subnets          = var.subnet_ids  # private subnets for ECS tasks
    security_groups  = [aws_security_group.sg_ecs_task_alb.id]
    assign_public_ip = false  # No public IP needed in private subnets with NAT
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg_alb_http.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  depends_on = [
    aws_lb.alb_ecs,
    aws_lb_listener.alb_listener_http,
    aws_lb_target_group.tg_alb_http
  ]
}

# ------------------------------------------------------------------------
# CREATE ECS TASK
# ------------------------------------------------------------------------

locals {
  task_tags = {
    Name        = "${var.env}-${var.aws_region}-${var.app_name}-ecs-task"
    Application = var.app_name
    Service     = "ECS"
    Purpose     = "Application Task Definition"
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.env}-${var.aws_region}-${var.app_name}-ecs-task"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  requires_compatibilities = var.requires_compatibilities
  network_mode             = var.network_mode
  execution_role_arn       = "arn:aws:iam::${var.aws_account_id}:role/ecsTaskExecutionRole"
  task_role_arn            = "arn:aws:iam::${var.aws_account_id}:role/ecsTaskExecutionRole"
  tags                     = local.task_tags
  container_definitions = jsonencode([
    {
      name      = var.app_name
      image     = var.app_image
      cpu       = var.container_cpu
      memory    = var.container_memory
      essential = var.essential
      environment = [
        for key, value in var.env_vars : {
          name  = key
          value = value
        }
      ]
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/log-group/${var.env}/${var.app_name}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = var.app_name
        }
      }
    }
  ])
}

# ------------------------------------------------------------------------
# CREATE A SECURITY GROUP FOR THE ECS TASK
# ------------------------------------------------------------------------

resource "aws_security_group" "sg_ecs_task_alb" {
  name        = "${var.env}-${var.aws_region}-${var.app_name}-security-group-ecs-task-alb"
  description = "Allow inbound traffic only from ALB to ECS Cluster."
  vpc_id      = var.vpc_id

  egress {
    description = "All outbound traffic for container operations"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.env}-${var.aws_region}-${var.app_name}-sg-ecs-task"
    Application = var.app_name
    Service     = "ECS Security Group"
    Purpose     = "ECS Task Network Security"
  }
}

# Separate ingress rule to break circular dependency
resource "aws_security_group_rule" "ecs_task_ingress_from_alb" {
  type                     = "ingress"
  description              = "Allow traffic from ALB to container port"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg_alb.id
  security_group_id        = aws_security_group.sg_ecs_task_alb.id
}

# ------------------------------------------------------------------------
# ALB for ECS SERVICE
# ------------------------------------------------------------------------

locals {
  alb_tags = {
    Name        = "${var.env}-${var.aws_region}-${var.app_name}-alb"
    Application = var.app_name
    Service     = "ALB"
    Purpose     = "Application Load Balancer"
  }
}

resource "aws_lb" "alb_ecs" {
  name               = "${var.env}-${var.aws_region}-${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = var.alb_subnet_ids  # public subnets for internet-facing ALB
  tags               = local.alb_tags
}

resource "aws_security_group" "sg_alb" {
  name        = "${var.env}-${var.aws_region}-${var.app_name}-security-group-alb"
  description = "Security group for ALB. Traffic to/from internet to/from ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.env}-${var.aws_region}-${var.app_name}-sg-alb"
    Application = var.app_name
    Service     = "ALB Security Group"
    Purpose     = "Application Load Balancer Network Security"
  }
}

# Separate egress rule to break circular dependency
resource "aws_security_group_rule" "alb_egress_to_ecs_tasks" {
  type                     = "egress"
  description              = "ALB to ECS tasks communication"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg_ecs_task_alb.id
  security_group_id        = aws_security_group.sg_alb.id
}

resource "aws_lb_listener" "alb_listener_http" {
  load_balancer_arn = aws_lb.alb_ecs.arn
  port              = var.alb_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_alb_http.arn
  }
}

resource "aws_lb_target_group" "tg_alb_http" {
  name        = "${var.env}-${var.app_name}-tg-alb-http" # `aws_region` not included to avoid exceeding 32 characters
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = var.health_check_path
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    matcher             = var.health_check_matcher
  }
}

# ------------------------------------------------------------------------
# CREATE CLOUDWATCH LOG GROUP
# ------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/log-group/${var.env}/${var.app_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "main" {
  name           = "/ecs/log-stream/${var.env}/${var.app_name}"
  log_group_name = aws_cloudwatch_log_group.main.name
}

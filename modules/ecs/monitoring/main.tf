# ------------------------------------------------------------------------
# GRAFANA ECS SERVICE
# ------------------------------------------------------------------------

resource "aws_ecs_service" "grafana" {
  name                 = "${var.env}-grafana-service"
  cluster              = var.ecs_cluster_id
  task_definition      = aws_ecs_task_definition.grafana.arn
  desired_count        = var.grafana_desired_count
  launch_type          = "FARGATE"
  force_new_deployment = true
  tags                 = local.grafana_tags

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.grafana.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana.arn
    container_name   = "grafana"
    container_port   = 3000
  }

  depends_on = [
    aws_lb_listener.grafana_http,
    aws_efs_mount_target.grafana
  ]
}

# ------------------------------------------------------------------------
# GRAFANA ECS TASK DEFINITION
# ------------------------------------------------------------------------

locals {
  grafana_tags = {
    Name        = "${var.env}-${var.aws_region}-grafana"
    Application = "grafana"
    Service     = "Monitoring"
    Purpose     = "Observability Platform"
  }
}

resource "aws_ecs_task_definition" "grafana" {
  family                   = "${var.env}-${var.aws_region}-grafana-task"
  cpu                      = var.grafana_task_cpu
  memory                   = var.grafana_task_memory
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.grafana_execution.arn
  task_role_arn            = aws_iam_role.grafana_task.arn
  tags                     = local.grafana_tags

  container_definitions = jsonencode([
    {
      name      = "grafana"
      image     = var.grafana_image
      cpu       = var.grafana_container_cpu
      memory    = var.grafana_container_memory
      essential = true

      environment = [
        {
          name  = "GF_SERVER_ROOT_URL"
          value = "http://${var.grafana_domain}"
        },
        {
          name  = "GF_SECURITY_ADMIN_USER"
          value = var.grafana_admin_user
        },
        {
          name  = "GF_AUTH_ANONYMOUS_ENABLED"
          value = "false"
        },
        {
          name  = "GF_INSTALL_PLUGINS"
          value = "grafana-clock-panel,grafana-piechart-panel,cloudwatch"
        }
      ]

      secrets = [
        {
          name      = "GF_SECURITY_ADMIN_PASSWORD"
          valueFrom = aws_secretsmanager_secret.grafana_admin_password.arn
        }
      ]

      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.grafana.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "grafana"
        }
      }

      mountPoints = [
        {
          sourceVolume  = "grafana-storage"
          containerPath = "/var/lib/grafana"
          readOnly      = false
        }
      ]
    }
  ])

  volume {
    name = "grafana-storage"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.grafana.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.grafana.id
      }
    }
  }
}

# ------------------------------------------------------------------------
# EFS FOR GRAFANA DATA PERSISTENCE
# ------------------------------------------------------------------------

resource "aws_efs_file_system" "grafana" {
  creation_token = "${var.env}-grafana-efs"
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(local.grafana_tags, {
    Name = "${var.env}-grafana-efs"
  })
}

resource "aws_efs_access_point" "grafana" {
  file_system_id = aws_efs_file_system.grafana.id

  posix_user {
    gid = 472
    uid = 472
  }

  root_directory {
    path = "/grafana"
    creation_info {
      owner_gid   = 472
      owner_uid   = 472
      permissions = "755"
    }
  }

  tags = merge(local.grafana_tags, {
    Name = "${var.env}-grafana-efs-access-point"
  })
}

resource "aws_efs_mount_target" "grafana" {
  count = length(var.subnet_ids)

  file_system_id  = aws_efs_file_system.grafana.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

# ------------------------------------------------------------------------
# SECURITY GROUPS
# ------------------------------------------------------------------------

resource "aws_security_group" "grafana" {
  name        = "${var.env}-${var.aws_region}-grafana-sg"
  description = "Security group for Grafana ECS tasks"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.grafana_tags, {
    Name = "${var.env}-grafana-sg"
  })
}

resource "aws_security_group_rule" "grafana_from_alb" {
  type                     = "ingress"
  description              = "Allow traffic from ALB to Grafana"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.grafana_alb.id
  security_group_id        = aws_security_group.grafana.id
}

resource "aws_security_group_rule" "grafana_to_efs" {
  type                     = "ingress"
  description              = "Allow Grafana to access EFS"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.grafana.id
  security_group_id        = aws_security_group.efs.id
}

resource "aws_security_group" "efs" {
  name        = "${var.env}-${var.aws_region}-grafana-efs-sg"
  description = "Security group for Grafana EFS"
  vpc_id      = var.vpc_id

  tags = merge(local.grafana_tags, {
    Name = "${var.env}-grafana-efs-sg"
  })
}

resource "aws_security_group" "grafana_alb" {
  name        = "${var.env}-${var.aws_region}-grafana-alb-sg"
  description = "Security group for Grafana ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.grafana_allowed_cidrs
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.grafana_allowed_cidrs
  }

  tags = merge(local.grafana_tags, {
    Name = "${var.env}-grafana-alb-sg"
  })
}

resource "aws_security_group_rule" "grafana_alb_to_tasks" {
  type                     = "egress"
  description              = "ALB to Grafana tasks"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.grafana.id
  security_group_id        = aws_security_group.grafana_alb.id
}

# ------------------------------------------------------------------------
# APPLICATION LOAD BALANCER
# ------------------------------------------------------------------------

resource "aws_lb" "grafana_alb" {
  name               = "${var.env}-${var.aws_region}-grafana-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.grafana_alb.id]
  subnets            = var.alb_subnet_ids

  tags = merge(local.grafana_tags, {
    Name = "${var.env}-grafana-alb"
  })
}

resource "aws_lb_target_group" "grafana" {
  name        = "${var.env}-grafana-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/api/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = merge(local.grafana_tags, {
    Name = "${var.env}-grafana-tg"
  })
}

resource "aws_lb_listener" "grafana_http" {
  load_balancer_arn = aws_lb.grafana_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }
}

# ------------------------------------------------------------------------
# IAM ROLES
# ------------------------------------------------------------------------

resource "aws_iam_role" "grafana_execution" {
  name = "${var.env}-grafana-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.grafana_tags
}

resource "aws_iam_role_policy_attachment" "grafana_execution" {
  role       = aws_iam_role.grafana_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "grafana_secrets" {
  name = "${var.env}-grafana-secrets-policy"
  role = aws_iam_role.grafana_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.grafana_admin_password.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "grafana_task" {
  name = "${var.env}-grafana-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.grafana_tags
}

resource "aws_iam_role_policy" "grafana_cloudwatch" {
  name = "${var.env}-grafana-cloudwatch-policy"
  role = aws_iam_role.grafana_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData",
          "ec2:DescribeRegions",
          "ec2:DescribeInstances",
          "ecs:ListClusters",
          "ecs:ListServices",
          "ecs:DescribeServices",
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeContainerInstances",
          "logs:DescribeLogGroups",
          "logs:GetLogGroupFields",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:GetQueryResults",
          "logs:GetLogEvents",
          "tag:GetResources"
        ]
        Resource = "*"
      }
    ]
  })
}

# ------------------------------------------------------------------------
# SECRETS MANAGER FOR GRAFANA PASSWORD
# ------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "grafana_admin_password" {
  name        = "${var.env}-grafana-admin-password"
  description = "Grafana admin password"

  tags = local.grafana_tags
}

resource "aws_secretsmanager_secret_version" "grafana_admin_password" {
  secret_id     = aws_secretsmanager_secret.grafana_admin_password.id
  secret_string = var.grafana_admin_password
}

# ------------------------------------------------------------------------
# CLOUDWATCH LOG GROUP
# ------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/ecs/${var.env}/grafana"
  retention_in_days = 7

  tags = local.grafana_tags
}

resource "aws_security_group" "wiki-ecs-sg" {
  vpc_id = aws_vpc.wiki-js-vpc.id
  name = "wiki-ecs-sg"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group_rule" "wiki-rds-ingress" {
  security_group_id = aws_security_group.wiki-rds-sg.id
  from_port = 5432
  to_port = 5432
  protocol = "tcp"
  type = "ingress"
  source_security_group_id = aws_security_group.wiki-ecs-sg.id
}

resource "aws_ecs_cluster" "wiki-cluster" {
  name = "wiki-js-tf-cluster"
  setting {
    name = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "wiki-cap-providers" {
  cluster_name = aws_ecs_cluster.wiki-cluster.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight = 10
  }
}

data "aws_secretsmanager_secret" "wiki-secret" {
  arn = aws_db_instance.wiki-rds.master_user_secret[0].secret_arn
}

data "aws_secretsmanager_secret_version" "wiki-passwd" {
  secret_id = data.aws_secretsmanager_secret.wiki-secret.id
}

resource "aws_iam_role" "wiki-task-logs-role" {
  name = "wiki-task-logs-role"
  assume_role_policy = <<ASSUME_POLICY
  {
    "Version": "2008-10-17",
    "Statement": 
    [
      {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
              "Service": "ecs-tasks.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
      }
    ]
  }
  ASSUME_POLICY
}

resource "aws_iam_role_policy_attachment" "wiki-task-logs-policy" {
  role = aws_iam_role.wiki-task-logs-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "wiki-js-logs" {
  name = "wiki-js-tasks"
}

resource "aws_ecs_task_definition" "wiki-js-task" {
  family = "wiki-js-task"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = 256
  memory = 512
  execution_role_arn = aws_iam_role.wiki-task-logs-role.arn
  container_definitions = jsonencode(
    [
      {
        name = "wikijs",
        image = "ghcr.io/requarks/wiki:2",
        cpu = 256,
        memory = 512,
        essential = true,
        portMappings = [
          {
            containerPort = 3000,
            hostPort = 3000
          }
        ],
        environment = [
          {
            name = "DB_TYPE",
            value = "postgres"
          },
          {
            name = "DB_SSL",
            value = "false"
          },
          {
            name = "DB_PORT",
            value = "5432"
          },
          {
            name = "DB_HOST",
            value = aws_db_instance.wiki-rds.address
          },
          {
            name = "DB_NAME",
            value = "wikijs"
          },
          {
            name = "DB_USER",
            value = "postgres"
          },
          {
            name = "DB_PASS",
            value = jsondecode(data.aws_secretsmanager_secret_version.wiki-passwd.secret_string)["password"]
          }
        ],
        logConfiguration = {
          logDriver = "awslogs",
          options = {
            awslogs-group = "wiki-js-tasks",
            awslogs-region = "us-east-1",
            awslogs-stream-prefix = "wikijs"
          }
        }
      }
    ]
  )
}

resource "aws_lb_target_group" "wiki-js-ltg" {
  name = "wikijs-ltg"
  target_type = "ip"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.wiki-js-vpc.id

  health_check {
    port = 3000
    healthy_threshold = 2
    unhealthy_threshold = 10
    timeout = 29
    interval = 31
  }
}

resource "aws_security_group" "wiki-js-lb-sg" {
  vpc_id = aws_vpc.wiki-js-vpc.id
  name = "wiki-js-lb-sg"
}

resource "aws_security_group_rule" "wiki-lb-ingress" {
  security_group_id = aws_security_group.wiki-js-lb-sg.id
  from_port = 80
  to_port = 80
  protocol = "tcp"
  type = "ingress"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "wiki-lb-ecs-access" {
  security_group_id = aws_security_group.wiki-js-lb-sg.id
  from_port = 3000
  to_port = 3000
  protocol = "tcp"
  type = "egress"
  source_security_group_id = aws_security_group.wiki-ecs-sg.id
}

resource "aws_security_group_rule" "wiki-ecs-allow-lb-access" {
  security_group_id = aws_security_group.wiki-ecs-sg.id
  from_port = 3000
  to_port = 3000
  protocol = "tcp"
  type = "ingress"
  source_security_group_id = aws_security_group.wiki-js-lb-sg.id
}

resource "aws_lb" "wiki-js-alb" {
  name = "wikijs-lb-tf"
  internal = false
  load_balancer_type = "application"
  subnets = [aws_subnet.wiki-js-subnets["public1"].id,
             aws_subnet.wiki-js-subnets["public2"].id]
  security_groups = [aws_security_group.wiki-js-lb-sg.id]
}

resource "aws_lb_listener" "wiki-js-alb-http-listener" {
  load_balancer_arn = aws_lb.wiki-js-alb.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.wiki-js-ltg.arn
  }
}

resource "aws_ecs_service" "wiki-js-service" {
  name = "wikijs"
  cluster = aws_ecs_cluster.wiki-cluster.id
  task_definition = aws_ecs_task_definition.wiki-js-task.arn
  launch_type = "FARGATE"
  desired_count = 1
  network_configuration {
    subnets = [aws_subnet.wiki-js-subnets["private"].id]
    security_groups = [aws_security_group.wiki-ecs-sg.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.wiki-js-ltg.arn
    container_name = "wikijs"
    container_port = 3000
  }

  depends_on = [aws_lb_listener.wiki-js-alb-http-listener]
}
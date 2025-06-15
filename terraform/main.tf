terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  services = ["ms1", "ms2"]
}

resource "aws_ecs_cluster" "my_cluster" {
  name = var.cluster_name
}

resource "aws_ecs_task_definition" "apps" {
  family                   = "ms1"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
  container_definitions = jsonencode([
    {
      name  = "ms1"
      image = var.image1name
      # cpu       = 10
      # memory    = 256
      essential = true
      secrets = [
        {
          name      = "TOKEN"
          valueFrom = aws_ssm_parameter.token.arn
        }
      ]
      Environment = [
        { name : "QUEUE_NAME", value : var.queue_name },
        { name : "AWS_REGION", value : "eu-central-1" }
      ],
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }

    },
    {
      name  = "ms2"
      image = var.image2name
      # essential = true
      Environment = [
        { name : "QUEUE_NAME", value : var.queue_name },
        { name : "S3_BUCKET", value : aws_s3_bucket.bucket.id },
        { name : "AWS_REGION", value : "eu-central-1" }

      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }


    }
  ])
}

resource "aws_ecs_service" "apps" {
  name            = "eladik-apps"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.apps.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ms1_tg.arn
    container_name   = "ms1"
    container_port   = 8080
  }

}

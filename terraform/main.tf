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
  family             = "ms1"
  network_mode       = "awsvpc"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "ms1"
      image     = var.image1name
      cpu       = 10
      memory    = 256
      essential = true
      secrets = [
        {
          name      = "TOKEN"
          valueFrom = aws_ssm_parameter.token.arn
        }
      ]
      Environment = [
        { "name" : "QUEUE_NAME", "value" : var.queue_name }
      ],
      #   portMappings = [
      #     {
      #       containerPort = 8080
      #       hostPort      = 8080
      #     }
      #   ]
    },
    {
      name      = "ms2"
      image     = var.image2name
      cpu       = 10
      memory    = 256
      essential = true
      Environment = [
        { "name" : "QUEUE_NAME", "value" : var.queue_name },
        { "name" : "S3_BUCKET", "value" : aws_s3_bucket.bucket.bucket_regional_domain_name }
      ],

    }
  ])
}

resource "aws_ecs_service" "apps" {
  name            = "eladik-apps"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.apps.arn
  desired_count   = 1
  #   iam_role        = aws_iam_role.ecs_task_execution_role.arn
  #   depends_on      = [aws_iam_role_policy.ecs_task_execution_role]


  load_balancer {
    target_group_arn = aws_lb_target_group.ms1_tg.arn
    container_name   = "ms1"
    container_port   = 8080
  }

}

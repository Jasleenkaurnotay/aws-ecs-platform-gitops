aws_region = "us-east-1"
aws_profile = "terraform"
project_name = "devops-quiz"
vpc_name = "devops-quiz-vpc"
vpc_cidr = "192.168.0.0/16"
environment = "dev"
public_subnet_data = [
    { cidr = "192.168.0.0/18", availability_zone = "us-east-1a", prefix = "pub"},
    { cidr = "192.168.64.0/18", availability_zone = "us-east-1b", prefix = "pub"}
]
private_subnet_data = [
    { cidr = "192.168.128.0/18", availability_zone = "us-east-1a", prefix = "pvt" },
    { cidr = "192.168.192.0/18", availability_zone = "us-east-1b", prefix = "pvt" }
]
need_nat_gateway = true
need_single_nat_gateway = true
db_name = "devops_learning"
db_username = "postgres"
db_password = "changeme123"
db_instance_size = "db.t3.medium"
ecs_cluster_name       = "devops-quiz-dev"
namespace_name         = "devops-quiz-namespace"
ecs_task_iam_role_name = "devops-quiz-ecs-execution-role"

ecs_task_def = [
  {
    task_def_family = "frontend"
    os              = "LINUX"
    cpu             = 256
    memory          = 512
    launch_type     = "FARGATE"
    cont_def = {
      name       = "frontend"
      image      = "067270456427.dkr.ecr.us-east-1.amazonaws.com/devopsquiz/frontend:latest"
      cpu        = 256
      memory     = 512
      essential  = true
      cont_port  = 80
      host_port  = 80
      log_group  = "/ecs/frontend"
      environment = [
        { name = "PORT",        value = "80" },
        { name = "BACKEND_URL", value = "http://backend.devops-quiz-namespace:8000" }
      ]
      secret = []
    }
  },
  {
    task_def_family = "backend"
    os              = "LINUX"
    cpu             = 256
    memory          = 512
    launch_type     = "FARGATE"
    cont_def = {
      name       = "backend"
      image      = "067270456427.dkr.ecr.us-east-1.amazonaws.com/devopsquiz/backend:latest"
      cpu        = 256
      memory     = 512
      essential  = true
      cont_port  = 8000
      host_port  = 8000
      log_group  = "/ecs/backend"
      environment = [
        { name = "FLASK_DEBUG",               value = "1" },
        { name = "MAX_QUIZ_QUESTIONS",        value = "15" },
        { name = "PASS_THRESHOLD",            value = "70" },
        { name = "QUIZ_SESSION_TTL_MINUTES",  value = "60" },
        { name = "LEADERBOARD_DEFAULT_LIMIT", value = "50" },
        { name = "SECRET_KEY",                value = "dev-secret-key" }
      ]
      secret = [
        { name = "DATABASE_URL", valueFrom = "arn:aws:secretsmanager:us-east-1:067270456427:secret:devops-quiz-dev-db-url-zBiP2r" }
      ]
    }
  }
]

ecs_service = [
  {
    name        = "frontend"
    is_frontend = true
    num_tasks   = 1
    need_alb    = true
    svc_conn_conf = {
      enable = true
      service = {
        port_alias = "frontend"
        disc_name  = "frontend"
        alias = {
          dns  = "frontend.devops-quiz-namespace"
          port = 80
        }
        log_conf = {
          style        = "json"
          query_params = ""
        }
      }
    }
    network_conf = {
      pub_ip = false
      sg     = []
      subnet = []
    }
  },
  {
    name        = "backend"
    is_frontend = false
    num_tasks   = 1
    need_alb    = false
    svc_conn_conf = {
      enable = true
      service = {
        port_alias = "backend"
        disc_name  = "backend"
        alias = {
          dns  = "backend.devops-quiz-namespace"
          port = 8000
        }
        log_conf = {
          style        = "json"
          query_params = ""
        }
      }
    }
    network_conf = {
      pub_ip = false
      sg     = []
      subnet = []
    }
  }
]

alb = {
  name = "devops-quiz-alb"
}

alb_listener = [
  { port = 80, protocol = "HTTP" }
]

target_group = {
  name     = "devops-quiz-tg"
  port     = 80
  protocol = "HTTP"
  healthcheck_conf = {
    needed              = true
    path                = "/health"
    port                = 80
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}
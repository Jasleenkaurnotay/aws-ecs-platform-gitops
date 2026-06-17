# Create ALB fist
resource "aws_lb" "alb" {
    name = var.alb.name
    subnets = var.alb.subnets
    load_balancer_type = "application"
    security_groups = [var.alb.sg]
    tags = {
        Name = "${var.project_name}-${var.environment}-var.alb.name"
        ProjectName = var.project_name
        ManagedBy = "Terraform"
    }
}


# Create 2 ALB listeners - HTTP and HTTPS
resource "aws_lb_listener" "alb_listeners" {
    count = length(var.alb_listener)    # Used to loop through the variable and create two listeners
    load_balancer_arn = aws_lb.alb.arn
    port = var.alb_listener[count.index].port
    protocol = var.alb_listener[count.index].protocol
    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.alb_tg.arn
    }
    tags = {
        Name = "${var.project_name}-${var.environment}-${count.index}"
        ProjectName = var.project_name
        ManagedBy = "Terraform"
    }
}

# Create ALB target group
resource "aws_lb_target_group" "alb_tg" {
    name = var.target_group.name
    port = var.target_group.port
    protocol = var.target_group.protocol
    vpc_id = var.vpc_id
    target_type = "ip"
    health_check {
      enabled = var.target_group.healthcheck_conf.needed
      path = var.target_group.healthcheck_conf.path
      protocol = var.target_group.healthcheck_conf.protocol
      interval = var.target_group.healthcheck_conf.interval
      timeout = var.target_group.healthcheck_conf.timeout
      healthy_threshold = var.target_group.healthcheck_conf.healthy_threshold
      unhealthy_threshold = var.target_group.healthcheck_conf.unhealthy_threshold
    }
}

# Create common IAM role for both services
# 1. use data source to generate custom policy for ecstaskexecutionrole

data "aws_iam_policy_document" "ecs_task_assume_role" {
    statement {
        actions = ["sts:AssumeRole"]
        effect = "Allow"

        principals {
          type = "Service"
          identifiers = ["ecs-tasks.amazonaws.com"]
        }
    }
}

# 2. Create the IAM role itself
resource "aws_iam_role" "ecs_execution_role" {
    name = var.ecs_task_iam_role_name
    assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

# 3. Attach the standard AWS Managed Policy (gives basic ECS execution rights) to the IAM role created above
resource "aws_iam_role_policy_attachemnt" "ecs_execution_managed" {
    role = aws_iam_role.ecs_execution_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 4. Create the custom JSON policy for log group creation
data "aws_iam_policy_document" "ecs_logs_inline" {
    statement {
      effect = "Allow"
      actions = ["logs:CreateLogGroup"]
      resources = ["*"]
    }
}

# 5. Attach the inline policy to your custom role
resource "aws_iam_role_policy" "ecs_execution_logs_policy" {
    name = "ecs-log-group-creation-policy"
    role = aws_iam_role.ecs_execution_role.id
    policy = data.aws_iam_policy_document.ecs_logs_inline.json
  
}

# Create cloudwatch log groups for FE and BE tasks
resource "aws_cloudwatch_log_group" "ecs_logs" {
    count = lenth(var.ecs_service)

    # Use the 'name' key from the current index object in the list
    name = "/ecs/${var.ecs_service[count.index].name}"
    retention_in_days = 5

    tags = {
        Name = "/ecs/${var.ecs_service[count.index].name}"
        ProjectName = var.project_name
        ManagedBy = "Terraform"
    }
}

# Create Service Connect namesapce
resource "aws_service_discovery_http_namespace" "svc_conn_namespace" {
    name = var.namespace_name
    description = "Name of the AWS CloudMap namespace"
}

# Create ECS cluster
resource "aws_ecs_cluster" "ecs_cluster" {
    name = var.ecs_cluster_name
    service_connect_defaults {
        namespace = aws_service_discovery_http_namespace.svc_conn_namespace.arn
    }
}

# Create ECS task definition for both FE and BE

resource "aws_ecs_task_definition" "service" {
    count = length(var.ecs_task_def)
    family = var.ecs_task_def[count.index].task_def_family
    cpu = var.ecs_task_def[count.index].cpu
    memory = var.ecs_task_def[count.index].memory
    network_mode = "awsvpc"
    requires_compatibilities = [var.ecs_task_def[count.index].launch_type]
    execution_role_arn = aws_iam_role.ecs_execution_role.arn

    runtime_platform {
      operating_system_family = var.ecs_task_def[count.index].os
      cpu_architecture = "X86_64"
    }

    container_definitions = jsondecode([
        {
            name      = var.ecs_task_def[count.index].cont_def.name
            image     = var.ecs_task_def[count.index].cont_def.image
            cpu       = var.ecs_task_def[count.index].cont_def.cpu
            memory    = var.ecs_task_def[count.index].cont_def.memory
            essential = var.ecs_task_def[count.index].cont_def.essential

            portMappings = [
                {
                    containerPort = var.ecs_task_def[count.index].cont_def.cont_port
                    hostPort      = var.ecs_task_def[count.index].cont_def.host_port
                    protocol      = "tcp"
                    name          = var.ecs_task_def[count.index].cont_def.name
                    appProtocol   = "http"
                }
            ]

        }
    ])
}

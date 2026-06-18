variable "project_name" {
  type = string
  description = "Name of project for which deployment is to happen"
}

variable "environment" {
  type        = string
  description = "Name of the environment for which the infrastructure is to be created"
  default     = "dev"
}

variable "ecs_cluster_name" {
    type = string
    description = "Define the name of the ECS cluster"
}

# Service connect namespace name
variable "namespace_name" {
    type = string
    description = "Define the name of service namespace"
}

# Modularized ECS task definition for all ECS services: FE and BE
variable "ecs_task_def" {
    type = list(object({
        task_def_family = string
        os = string
        cpu = number
        memory = number
        launch_type = string
        cont_def = object({
            cpu = number
            essential = bool
            image = string
            memory = number
            name = string
            cont_port = number
            host_port = number
            environment = list(object({
                name = string
                value = string
            }))
            log_group = string
            secret = list(object({
                name = string
                valueFrom = string
            }))
        })
    }))
    description = "List of ECS service definitions for various services in the application"
}

# Modularized ECS service definition for frontend & backend ECS services
variable "ecs_service" {
    type = list(object({
        name = string
        is_frontend = bool
        num_tasks = number
        need_alb = bool
        svc_conn_conf = object({
          enable = bool
          service = object({
            port_alias = string
            disc_name = string  
            alias = object({
              dns = string
              port = number
            })
            log_conf = object({             # cloudwatch log to log traffic between services
                style = string
                query_params = string
            })
          })
        })
        network_conf = object({
          pub_ip = bool
          sg = list(string)
          subnet = list(string) 
        })
    }))
    description = "Enter values specific to frontend and backend ECS services"
}

variable "ecs_task_iam_role_name" {
    type = string
    description = "Enter the name of the shared IAM task execution role for all ECS services"
}

# VPC ID
variable "vpc_id" {
  type       = string
  description = "VPC ID"
}

# Application Load Balancer
variable "alb" {
    type = object({
        name = string
        subnets = optional(list(string), [])
        sg = optional(list(string), [])
    })
    description = "Enter the name of the application load balancer"
}

# ALB listener, 2 listeners - HTTP and HTTPS
variable "alb_listener" {
    type = list(object({
        port = number
        protocol = string
    }))
    description = "Specify port and protocol of the two ALB listeners - HTTP and HTTPS"
}

# Target group, we need only one target group for the frontend
variable "target_group" {
    type = object({
      name = string
      port = number
      protocol = string
      healthcheck_conf = object({
        needed = bool
        path = string
        port = number
        protocol = string
        interval = number
        timeout = number
        healthy_threshold = number
        unhealthy_threshold = number
      })
    })
    description = "Specify FE ECS tasks' target group specifics"
}
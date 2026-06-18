module "network" {
    source = "./modules/network"
    vpc_name = var.vpc_name
    vpc_cidr = var.vpc_cidr
    environment = var.environment
    public_subnet_data = var.public_subnet_data
    private_subnet_data = var.private_subnet_data
    need_nat_gateway = var.need_nat_gateway
    need_single_nat_gateway = var.need_single_nat_gateway
}

module "database" {
    source = "./modules/database"
    vpc_id = module.network.vpc_id
    db_sg_id = module.network.db_sg_id
    private_subnet_ids = module.network.private_subnet_ids
    environment = var.environment
    project_name = var.project_name
    pvt_subnet_az = module.network.pvt_subnet_az
    db_name = var.db_name
    db_username = var.db_username
    db_password = var.db_password
    db_instance_size = var.db_instance_size
}

module "ecs" {
    source = "./modules/ecs"
    project_name = var.project_name
    environment = var.environment
    ecs_cluster_name = var.ecs_cluster_name
    namespace_name = var.namespace_name
    ecs_task_def = var.ecs_task_def
    ecs_service = local.ecs_services_with_network
    ecs_task_iam_role_name = var.ecs_task_iam_role_name
    vpc_id = module.network.vpc_id
    alb = {
        name = var.alb.name
        subnets = module.network.public_subnet_ids
        sg = [module.network.alb_sg_id]
    }
    alb_listener = var.alb_listener
    target_group = var.target_group
}
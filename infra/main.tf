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
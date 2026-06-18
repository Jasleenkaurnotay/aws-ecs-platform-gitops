locals {
    ecs_services_with_network = [
        for svc in var.ecs_service : merge(svc, {
            network_conf = {
            pub_ip = svc.network_conf.pub_ip
            subnet = module.network.private_subnet_ids
            sg = [svc.is_frontend ? module.network.fe_sg_id : module.network.be_sg_id]
            }
        })
    ]
}
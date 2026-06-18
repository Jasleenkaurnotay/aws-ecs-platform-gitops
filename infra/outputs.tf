output "alb_dns_name" {
  value = module.ecs.alb_dns_name
}

output "db_connection_string" {
  value     = module.database.db_connection_string
  sensitive = true
}
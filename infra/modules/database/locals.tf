locals {
    db_string = var.environment == "dev" ? "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.rds_db[0].address}:5432/${var.db_name}" : "postgresql://${var.db_username}:${var.db_password}@${aws_rds_cluster.aurora_writer[0].endpoint}:5432/${var.db_name}"
}
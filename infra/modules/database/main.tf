# Create DB subnet group
resource "aws_db_subnet_group" "rds_db_sub_group" {
    name = "rds-db-subnet-group"
    subnet_ids = var.private_subnet_ids
    tags = {
        Name = "${var.environment}-rds-db-subnet-group"
        ProjectName = var.project_name
        ManagedBy = "Terraform"
    }
}

# Create database writer instance - Aurora
resource "aws_rds_cluster" "aurora_writer" {
    count = var.environment == "dev" ? 0 : 1
    cluster_identifier = "${var.project_name}-${var.environment}-aurora-writer"
    engine = "aurora-postgresql"
    engine_version = "14.22"
    availability_zones = var.pvt_subnet_az
    database_name = var.db_name
    master_username = var.db_username
    master_password = var.db_password
    db_cluster_instance_class = var.db_instance_size
    db_subnet_group_name = aws_db_subnet_group.rds_db_sub_group.name
    vpc_security_group_ids = [var.db_sg_id]
    apply_immediately = true
    tags = {
        Name = "${var.project_name}-${var.environment}-aurora-writer"
        ProjectName = var.project_name
        ManagedBy = "Terraform"
    }
}

# Create database rds aurora cluster read instances -- Aurora
resource "aws_rds_cluster_instance" "aurora_read_replicas" {
    count = var.environment == "dev" ? 0 : 1
    cluster_identifier = aws_rds_cluster.aurora_writer[0].cluster_identifier    # Reference to the parent cluster
    instance_class = var.db_instance_size
    apply_immediately = true
    engine = aws_rds_cluster.aurora_writer[0].engine
    engine_version = aws_rds_cluster.aurora_writer[0].engine_version
    tags = {
        Name = "${var.project_name}-${var.environment}-reader-${count.index}"
        ProjectName = var.project_name
        ManagedBy = "Terraform"
    }
}

# Create dev environment RDS postgresql database
resource "aws_db_instance" "rds_db" {
    count = var.environment == "dev" ? 1 : 0
    identifier = "${var.project_name}-${var.environment}-rds-db"
    instance_class = var.db_instance_size
    allocated_storage = 20
    db_name = var.db_name
    username = var.db_username
    password = var.db_password
    publicly_accessible = false
    db_subnet_group_name = aws_db_subnet_group.rds_db_sub_group.name
    engine = "postgres"
    engine_version = "14.13"
    availability_zone = var.pvt_subnet_az[0]    # aws_db_instance for RDS takes availability_zone as a single string, not a list
    vpc_security_group_ids = [var.db_sg_id]
    skip_final_snapshot  = true
    apply_immediately = true
    tags = {
        Name = "${var.project_name}-${var.environment}-rds-db"
        ProjectName = var.project_name
        ManagedBy = "Terraform"
    }
}

# Create AWS Secrets manager secret metadata for DB URL
resource "aws_secretsmanager_secret" "db_url" {
    name = "${var.project_name}-${var.environment}-db-url"
    tags = {
        Name = "${var.project_name}-${var.environment}-db-url"
        ProjectName = var.project_name
        ManagedBy = "Terraform"
    }
}

# Create AWS secrets value
resource "aws_secretsmanager_secret_version" "db_url_value" {
    secret_id = aws_secretsmanager_secret.db_url.id
    secret_string = local.db_string
}
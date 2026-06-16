output "db_connection_string" {
    value = aws_secretsmanager_secret.db_url.arn
    description = "DB connection string ARN"
}

output "db_endpoint" {
    value = local.db_string
    description = "RDS database endpoint"
}
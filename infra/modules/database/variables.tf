variable "vpc_id" {
  type       = string
  description = "VPC ID"
}

variable "pvt_subnet_az" {
  type = list(string)
  description = "Availability zones of the VPC subnets"
}

variable "db_sg_id" {
  type = string
  description = "RDS DB security group ID"
}

variable "private_subnet_ids" {
    type = list(string)
    description = "List of all private subnets in the VPC"
}

# Variabalize database specifics
variable "db_name" {
  type = string
  description = "Name of Aurora database"
}

variable "db_username" {
  type = string
  description = "Master username of database"
}

variable "db_password" {
  type = string
  description = "Master password for database"
}

variable "db_instance_size" {
  type = string
  description = "Specify the db instance size"
}

# Project level variables

variable "environment" {
  type        = string
  description = "Name of the environment for which the infrastructure is to be created"
  default     = "dev"
}

variable "project_name" {
  type = string
  description = "Name of project for which deployment is to happen"
}
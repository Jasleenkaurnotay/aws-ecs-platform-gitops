variable "vpc_name" {
  type        = string
  description = "Prefix for the vpc"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "environment" {
  type        = string
  description = "Name of the environment for which the infrastructure is to be created"
  default     = "dev"
}

variable "public_subnet_data" {
  type = list(object({
    cidr              = string
    availability_zone = string
    prefix            = string
  }))
  description = "Provide CIDR, AZ and prefix for public subnets of the vpc"
}

variable "private_subnet_data" {
  type = list(object({
    cidr              = string
    availability_zone = string
    prefix            = string
  }))
  description = "Provide CIDR, AZ and prefix for private subnets of the vpc"
}

variable "need_nat_gateway" {
  type        = bool
  description = "Choice to create a NAT gateway in the vpc or not"
  default     = false
}

variable "need_single_nat_gateway" {
  type        = bool
  default     = false
  description = "Set to true for a single shared NAT gateway (cost-saving), false for one NAT per AZ (high availability)"
}
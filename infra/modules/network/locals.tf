locals {
  nat_count = var.need_nat_gateway ? (var.need_single_nat_gateway ? 1 : length(var.public_subnet_data)) : 0

  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.vpc_name
  }

  # converting the public subnet list(object) to a map
  public_subnet_map = {
    for subnet in var.public_subnet_data : subnet.cidr => subnet
  }

  # Converting the private subnet list(object) to a map
  private_subnet_map = {
    for subnet in var.private_subnet_data : subnet.cidr => subnet
  }
}
output "vpc_id" {
  value       = aws_vpc.vpc.id
  description = "VPC ID"
}

output "vpc_cidr" {
    value = aws_vpc.vpc.cidr_block
    description = "CIDR block of VPC"
}

output "public_subnet_ids" {
  value       = values(aws_subnet.pub_subnet)[*].id
  description = "List of all public subnets in the VPC"
}

output "private_subnet_ids" {
  value       = values(aws_subnet.pvt_subnet)[*].id
  description = "List of all private subnets in the VPC"
}

output "pvt_subnet_az" {
  description = "Avaolability zones of the VPC subnets"
  value = [for s in aws_subnet.pvt_subnet : s.availability_zone]
}

output "nat_gateway_ids" {
  value       = aws_nat_gateway.nat_gw[*].id
  description = "List of all Nat gateway IDs"
}

# output ALB security group ID
output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
  description = "ALB security group ID"
}

# output fe security group ID
output "fe_sg_id" {
  value = aws_security_group.fe_sg.id
  description = "FE ECS task's security group ID"
}

# output be security group ID
output "be_sg_id" {
  value = aws_security_group.be_sg.id
  description = "BE ECS task's security group ID"
}

# output db security group ID
output "db_sg_id" {
  value = aws_security_group.db_sg.id
  description = "RDS DB security group ID"
}
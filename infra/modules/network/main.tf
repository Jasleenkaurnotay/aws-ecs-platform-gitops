# Create VPC

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, { Name = "${var.vpc_name}" })
}

# Create public subnets
resource "aws_subnet" "pub_subnet" {
  # 1. Loop through your local map at the resource level
  for_each = local.public_subnet_map

  vpc_id = aws_vpc.vpc.id

  # 2. Reference the current item's data from the map

  cidr_block        = each.key
  availability_zone = each.value.availability_zone

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-${each.value.prefix}" })
}

# Create private subnets
resource "aws_subnet" "pvt_subnet" {
  # 1. Loop through your local map at the resource level
  for_each = local.private_subnet_map

  vpc_id = aws_vpc.vpc.id

  # 2. Reference the current item's data from the map
  cidr_block        = each.key
  availability_zone = each.value.availability_zone

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-${each.value.prefix}" })
}

# Create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-igw" })
}

# Create public route table
resource "aws_route_table" "pub_rt" {
  # No need to loop through the map, since a common route table is needed for all public subnets

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-public-rt" })
}

# Create route table association
resource "aws_route_table_association" "pub_rt_asst" {
  for_each       = local.public_subnet_map
  subnet_id      = aws_subnet.pub_subnet[each.key].id
  route_table_id = aws_route_table.pub_rt.id
}

# Create elastic IP 
resource "aws_eip" "nat_gw_eip" {
  # We need to allocate as many EIPs as there are NAT gateways
  count      = local.nat_count # Requests multiple EIPs
  depends_on = [aws_internet_gateway.igw]
  domain     = "vpc"
  tags       = merge(local.common_tags, { Name = "${var.vpc_name}-eip-${count.index + 1}" })
}

# Create NAT gateway
resource "aws_nat_gateway" "nat_gw" {
  count             = local.nat_count
  connectivity_type = "public"
  allocation_id     = aws_eip.nat_gw_eip[count.index].id
  subnet_id         = aws_subnet.pub_subnet[keys(local.public_subnet_map)[count.index]].id # Use keys function to convert public subnet map data into list for count to loop over
  depends_on        = [aws_internet_gateway.igw]

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-nat-gw-${count.index + 1}" })
}

# Create public route tables - one per AZ
resource "aws_route_table" "pvt_rt" {
  for_each = local.nat_count > 0 ? local.private_subnet_map : {}
  # If nat_count = 0, there are no NAT gateways. In that scenario, we should not be creating the below mentioned route

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[var.need_single_nat_gateway ? 0 : index(keys(local.private_subnet_map), each.key)].id
    # If single NAT gateway, always use NATGateway[0], if HA, use the NAT gateway at the same position as this subnet in the map
  }

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-private-${each.value.availability_zone}-rt" })
}

# Create route table association
resource "aws_route_table_association" "pvt_rt_asst" {
  for_each = local.nat_count > 0 ? local.private_subnet_map : {}
  # pvt_rt only exits when nat_count > 0. If there is no NAT, pvt_rt doesn't exits - so referencing it in the association crashes

  subnet_id      = aws_subnet.pvt_subnet[each.key].id
  route_table_id = aws_route_table.pvt_rt[each.key].id
}
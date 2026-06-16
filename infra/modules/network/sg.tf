# Create ALB security group

resource "aws_security_group" "alb_sg" {
    name = "${var.environment}-alb-sg"
    description = "Security group attached to ALB"
    vpc_id = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_in" {
    security_group_id = aws_security_group.alb_sg.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 443
    ip_protocol = "tcp"
    to_port = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_in" {
    security_group_id = aws_security_group.alb_sg.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 80
    ip_protocol = "tcp"
    to_port = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_to_fe" {
    security_group_id = aws_security_group.alb_sg.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
}

# Create frontend security group

resource "aws_security_group" "fe_sg" {
    name = "${var.environment}-fe-sg"
    description = "Security group attached to ECS frontend tasks"
    vpc_id = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_app_traffic" {
    security_group_id = aws_security_group.fe_sg.id     # group receiving the traffic
    referenced_security_group_id =  aws_security_group.alb_sg.id    # group sending the traffic
    from_port = 80
    ip_protocol = "tcp"
    to_port = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_to_be" {
    security_group_id = aws_security_group.fe_sg.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
}


# Create backend security group

resource "aws_security_group" "be_sg" {
    name = "${var.environment}-be-sg"
    description = "Security group attached to ECS backend tasks"
    vpc_id = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_be_traffic" {
    security_group_id = aws_security_group.be_sg.id     # group receiving the traffic
    referenced_security_group_id =  aws_security_group.fe_sg.id    # group sending the traffic
    from_port = 8000
    ip_protocol = "tcp"
    to_port = 8000
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
    security_group_id = aws_security_group.be_sg.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
}

# Create database security group

resource "aws_security_group" "db_sg" {
    name = "${var.environment}-db-sg"
    description = "Security group attached to database"
    vpc_id = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_db_traffic" {
    security_group_id = aws_security_group.db_sg.id     # group receiving the traffic
    referenced_security_group_id =  aws_security_group.be_sg.id    # group sending the traffic
    from_port = 5432
    ip_protocol = "tcp"
    to_port = 5432
}

resource "aws_vpc_security_group_egress_rule" "allow_all_db_out" {
    security_group_id = aws_security_group.db_sg.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
}
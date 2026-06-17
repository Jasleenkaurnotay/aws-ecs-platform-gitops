output "alb_dns_name" {
    value = aws_lb.alb.dns_name
    description = "Public DNS name of the Application load balancer"
}
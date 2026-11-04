resource "aws_vpc_endpoint" "ssm" {
  for_each = toset([
    "ssm",
    "ssmmessages",
    "ec2messages"
  ])

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.endpoint_security_group_id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-${each.value}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}
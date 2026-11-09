resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-${var.environment}-ec2-sg"
  description = "Security group for EC2"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-sg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Security group for rds"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-sg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}


resource "aws_vpc_security_group_ingress_rule" "rds_from_ec2" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.ec2.id

  ip_protocol = "tcp"
  from_port   = 3306
  to_port     = 3306
  description = "Allow MySQL access from automation EC2"
}


resource "aws_security_group" "ssm_endpoints" {
  name        = "${var.project_name}-${var.environment}-ssm-endpoints-sg"
  description = "Allow HTTPS from automation EC2 to SSM endpoints"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.environment}-ssm-endpoints-sg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }

}

resource "aws_vpc_security_group_ingress_rule" "ssm_https_from_ec2" {
  security_group_id            = aws_security_group.ssm_endpoints.id
  referenced_security_group_id = aws_security_group.ec2.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "Allow HTTPS from automation EC2"
}

resource "aws_vpc_security_group_egress_rule" "ec2_https_to_ssm" {
  security_group_id            = aws_security_group.ec2.id
  referenced_security_group_id = aws_security_group.ssm_endpoints.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "Allow HTTPS to SSM endpoint"
}

resource "aws_vpc_security_group_egress_rule" "ec2_mysql_to_rds" {
  security_group_id            = aws_security_group.ec2.id
  referenced_security_group_id = aws_security_group.rds.id

  ip_protocol = "tcp"
  from_port   = 3306
  to_port     = 3306

  description = "Allow MySQL access to RDS"
}

data "aws_prefix_list" "S3" {
  name = "com.amazonaws.${var.aws_region}.s3"
}

resource "aws_vpc_security_group_egress_rule" "ec2_https_to_s3" {
  security_group_id = aws_security_group.ec2.id
  prefix_list_id    = data.aws_prefix_list.S3.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "Allow HTTPS to S3 gateway endpoint"
}
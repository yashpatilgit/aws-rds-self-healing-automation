resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-${var.environment}-db-subnet-group"
  description = "Private subnet group for RDS MySQL"
  subnet_ids  = var.private_subnet_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_db_instance" "main" {

  identifier             = "${var.project_name}-${var.environment}-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  max_allocated_storage  = 50
  storage_type           = "gp3"
  db_name                = var.db_name
  username               = "dbadmin"
  password               = random_password.master.result
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]

  publicly_accessible     = false
  multi_az                = false
  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true //delete rds without taking the final snapshot

  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  tags = {
    Name        = "${var.project_name}-${var.environment}-mysql"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "random_password" "master" {
  length  = 15
  special = false
}

resource "random_password" "app_user" {
  length  = 15
  special = false
}

resource "random_password" "readonly_user" {
  length  = 15
  special = false
}

resource "random_password" "ops_automation" {
  length  = 15
  special = false
}

resource "aws_secretsmanager_secret" "rds_master" {
  name = "aws-rds-self-healing/dev/rds-master"
}

resource "aws_secretsmanager_secret_version" "rds_master" {
  secret_id = aws_secretsmanager_secret.rds_master.id

  secret_string = jsonencode({
    username = "dbadmin"
    password = random_password.master.result
  })
}

resource "aws_secretsmanager_secret" "database_users" {
  name = "aws-rds-self-healing/dev/database-users"
}

resource "aws_secretsmanager_secret_version" "database_users" {
  secret_id = aws_secretsmanager_secret.database_users.id

  secret_string = jsonencode({
    app_user = {
      username = "app_user"
      password = random_password.app_user.result
    }
    readonly_user = {
      username = "readonly_user"
      password = random_password.readonly_user.result
    }
    ops_automation = {
      username = "ops_automation"
      password = random_password.ops_automation.result
    }
  })

}


resource "aws_kms_key" "rds" {
  description             = "Customer-managed key for RDS encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-kms"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}
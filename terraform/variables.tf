variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the project VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_name" {
  description = "Initial RDS database name"
  type        = string
  default     = "automation_db"
}

variable "project_name" {
  description = "Name of the AWS automation project"
  type        = string
  default     = "aws-rds-self-healing"
}

variable "availability_zones" {
  description = "Availability zone"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "public_subnet_cidr" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidr" {
  type    = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}
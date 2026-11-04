variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for creating endpoints"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for interface endpoints"
  type        = list(string)
}

variable "endpoint_security_group_id" {
  description = "Security group ID for VPC endpoints"
  type        = string
}

variable "aws_region" {
  description = "Region for AWS endpoint"
  type        = string
}
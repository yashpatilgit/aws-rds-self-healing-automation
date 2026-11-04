variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "subnet_id" {
  description = "Private subnet ID for automation EC2"
  type        = string
}

variable "ec2_security_group_id" {
  description = "Security group ID for automation EC2"
  type        = string
}
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "vpc_id" {
  type        = string
  description = "ID of VPC"
}

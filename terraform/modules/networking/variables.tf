variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  description = "availability zones for the subnet distributiom"
  type        = list(string)
}

variable "public_subnet_cidr" {
  description = "CIDR for public subnets"
  type        = list(string)
}

variable "private_subnet_cidr" {
  description = "CIDR for private subnets"
  type        = list(string)
}
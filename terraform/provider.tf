terraform {
  required_providers {
    aws = {
      version = ">= 5.0, < 7.0"
      source  = "hashicorp/aws"
    }
  }
  required_version = ">= 1.6.0, < 2.0.0"
}


provider "aws" {
  region = var.aws_region
}
terraform {
  required_providers {
    aws = {
      version = ">= 5.0, < 7.0"
      source  = "hashicorp/aws"
    }
  }
  required_version = ">= 1.6.0, < 2.0.0"

  backend "s3" {
    bucket = "aws-rds-self-healing-tfstate-470309606650"
    key    = "aws-rds-self-healing/terraform.tfstate"
    region = "ap-south-1"
  }
}


provider "aws" {
  region = var.aws_region
}
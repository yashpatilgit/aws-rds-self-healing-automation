output "vpc_id" {
  value = module.networking.vpc_id
}

output "ec2_instance_id" {
  value = module.ec2.instance_id
}

output "ec2_private_ip" {
  value = module.ec2.private_ip
}

output "rds_endpoint" {
  value = module.rds.rds_endpoint
}
output "ec2_security_group_id" {
  value = aws_security_group.ec2.id
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}

output "ssm_endpoint_security_group_id" {
  description = "Security group ID for SSM VPC endpoints"
  value       = aws_security_group.ssm_endpoints.id
}
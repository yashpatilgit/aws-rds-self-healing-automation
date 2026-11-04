output "ssm_endpoint_ids" {
  description = "IDs of the system manager VPC endpoints"
  value = {
    for name, endpoint in aws_vpc_endpoint.ssm :
    name => endpoint.id

  }
}
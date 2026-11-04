output "vpc_id" {
  description = "ID of the project VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the project"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "IDs of public subnet"
  value       = aws_subnet.public[*].id
}

output "private_subnet_id" {
  description = "IDs of private subnet"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID of internet gateway"
  value       = aws_internet_gateway.gateway.id
}

output "public_route_table_id" {
  description = "ID of public rt"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of private rt"
  value       = aws_route_table.private.id
}
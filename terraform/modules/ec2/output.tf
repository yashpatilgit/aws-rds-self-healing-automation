output "instance_id" {
  description = "ID of the instance"
  value       = aws_instance.automation.id
}

output "private_ip" {
  description = "Private IP of the automation instance"
  value       = aws_instance.automation.private_ip
}
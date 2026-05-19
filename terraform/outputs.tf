output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app_server.id
}

output "instance_public_ip" {
  description = "Public IP for health checks and browser access"
  value       = aws_instance.app_server.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.app_server.private_ip
}

output "aws_key_name" {
  description = "Key pair attached to the instance"
  value       = aws_instance.app_server.key_name
}

output "ansible_inventory_file" {
  description = "Absolute path to generated inventory.ini"
  value       = local_file.ansible_inventory.filename
}

output "site_url" {
  description = "Deployed site URL"
  value       = "http://${aws_instance.app_server.public_ip}/"
}

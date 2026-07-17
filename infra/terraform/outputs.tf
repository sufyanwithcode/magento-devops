output "public_ip" {
  description = "Public IP of the Magento VM"
  value       = aws_instance.magento.public_ip
}

output "ssh_command" {
  value = "ssh ubuntu@${aws_instance.magento.public_ip}"
}

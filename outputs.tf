output "public_ec2_public_ip" {
  value = aws_instance.public_ec2.public_ip
}

output "private_ec2_private_ip" {
  value = aws_instance.private_ec2.private_ip
}

output "bastion_host_public_ip" {
  value = aws_instance.bastion_host.public_ip
}

output "private_key_path" {
  value = local_file.private_key.filename
}
output "vpc_id" {
  description = "ID du VPC créé"
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "IDs des sous-réseaux publics"
  value       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id, aws_subnet.public_subnet_3.id]
}

output "private_subnets" {
  description = "IDs des sous-réseaux privés"
  value       = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id, aws_subnet.private_subnet_3.id]
}
output "bastion_public_ip" {
  description = "Adresse IP publique de l'instance bastion"
  value       = aws_instance.bastion.public_ip
}
output "nextcloud_private_ip" {
  description = "Adresse IP Privée de l'instance nextcloud"
  value       = aws_instance.nextcloud.private_ip
}
resource "local_file" "ssh_config" {
  content = <<-EOT
    Host bastion
       Hostname ${aws_instance.bastion.public_ip}
       User ubuntu
       IdentitiesOnly yes
       IdentityFile /Users/dreasy/Downloads/bastion-out.pem

    Host nextcloud
       Hostname ${aws_instance.nextcloud.private_ip}
       User ubuntu
       ProxyCommand ssh -W %h:%p bastion
       IdentityFile /Users/dreasy/Downloads/nextcloud.pem
    EOT

  filename = "${path.module}/ssh_config"
}

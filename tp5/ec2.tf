data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"] # This is the owner ID for Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"] # Change as needed for different Ubuntu versions
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t4g.micro"
  key_name               = aws_key_pair.bastion.key_name
  subnet_id              = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  tags = {
    Name = "${local.name}-bastion-instance"
  }
}

resource "aws_instance" "nextcloud" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t4g.micro"
  key_name               = aws_key_pair.nextcloud.key_name
  subnet_id              = aws_subnet.private_subnet_2.id
  vpc_security_group_ids = [aws_security_group.private_app_sg.id]
  # User data to install NFS client and mount EFS
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y nfs-common
              sudo mkdir -p /mnt/efs
              sudo mount -t nfs4 -o nfsvers=4.1 ${aws_efs_file_system.nextcloud_efs.dns_name}:/ /mnt/efs
              sudo echo "${aws_efs_file_system.nextcloud_efs.dns_name}:/ /mnt/efs nfs4 defaults 0 0" | sudo tee -a /etc/fstab
              EOF


  tags = {
    Name = "${local.name}-nextcloud"
  }
}

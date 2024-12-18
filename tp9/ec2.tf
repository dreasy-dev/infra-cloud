# Fetch the latest Ubuntu AMI for ARM architecture
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's Owner ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Bastion Instance Configuration
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

# Route53 Zone for the training subdomain
data "aws_route53_zone" "training" {
  name = "training.akiros.it"
}

# Route53 Record for Nextcloud
resource "aws_route53_record" "nextcloud" {
  zone_id = data.aws_route53_zone.training.zone_id
  name    = "nextcloud-${local.user}.training.akiros.it"
  type    = "A"
  alias {
    name                   = aws_lb.nextcloud.dns_name
    zone_id                = aws_lb.nextcloud.zone_id
    evaluate_target_health = true
  }
}

# Generate User Data for Nextcloud Instance
locals {
  nextcloud_userdata = templatefile("${path.module}/userdata/nextcloud.sh",
    {
      efs_dns = aws_efs_file_system.nextcloud_efs.dns_name,
      db_name = aws_db_instance.nextcloud_rds.db_name,
      db_host = aws_db_instance.nextcloud_rds.address,
      db_user = aws_db_instance.nextcloud_rds.username,
      db_pass = "adminpassword", # Use secrets manager for better security
      fqdn    = aws_route53_record.nextcloud.fqdn,
      bucket  = "${local.user}-tp9-nextcloud", # New bucket integration
  })
}

# Nextcloud Instance Configuration
resource "aws_instance" "nextcloud" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t4g.micro"
  subnet_id              = aws_subnet.private_subnet_1.id
  vpc_security_group_ids = [aws_security_group.private_app_sg.id]
  key_name               = aws_key_pair.nextcloud.key_name
  user_data              = local.nextcloud_userdata
  iam_instance_profile   = aws_iam_instance_profile.nextcloud_instance_profile.name
  tags = {
    Name = "${local.name}-nextcloud-instance"
  }

  depends_on = [aws_route53_record.nextcloud]
}

# RDS Instance for Nextcloud
resource "aws_db_instance" "nextcloud_rds" {
  allocated_storage      = 20
  storage_type           = "gp2"
  instance_class         = "db.t4g.micro"
  engine                 = "mysql"
  engine_version         = "8.0"
  db_name                = "nextcloud"
  username               = "admin"
  password               = "adminpassword" # Use secrets manager for better security
  parameter_group_name   = "default.mysql8.0"
  db_subnet_group_name   = aws_db_subnet_group.rds_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  multi_az               = true
  publicly_accessible    = false
  storage_encrypted      = true
  skip_final_snapshot    = true
  tags                   = local.tags
}

# Outputs
output "nextcloud_dns" {
  value = aws_route53_record.nextcloud.fqdn
}

output "rds_endpoint" {
  value = aws_db_instance.nextcloud_rds.address
}
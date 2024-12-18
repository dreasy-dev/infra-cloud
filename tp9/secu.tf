resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.main.id

  # Autoriser SSH depuis l'IP du VPN de l'entreprise
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["195.7.117.146/32"]
  }

  # Autoriser SSH depuis l'IP de Cloud9
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["51.44.16.230/32"]
  }

  # Autoriser tout le trafic sortant
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-bastion-sg"
  }
}

resource "aws_security_group" "private_app_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # ici l'ip sera l'ip du vpn entreprise (ip d'ynov)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["195.7.117.146/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict as needed
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }



  tags = {
    Name = "${local.name}-private-app-sg"
  }
}


resource "aws_security_group" "rds_sg" {
  name        = "${local.name}-rds-sg"
  description = "Security group for RDS MySQL instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.private_app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-rds-sg"
  }
}

resource "aws_security_group" "efs_sg" {
  name        = "${local.name}-efs-sg"
  description = "Security group to secure access to EFS"
  vpc_id      = aws_vpc.main.id

  # Ingress: Allow only NFS traffic (port 2049) from Nextcloud EC2 instances
  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.private_app_sg.id]
  }

  # Egress: Allow all traffic (required for EFS operations)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-efs-sg"
  }
}
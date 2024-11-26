# Bastion ACL
resource "aws_network_acl" "bastion_acl" {
  vpc_id = aws_vpc.main.id
  subnet_ids = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id,
    aws_subnet.public_subnet_3.id
  ]

  tags = { Name = "${local.name}-bastion-acl" }
}

resource "aws_network_acl_rule" "allow_vpn_ssh" {
  network_acl_id = aws_network_acl.bastion_acl.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "195.7.117.146/32"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "allow_secondary_ip_ssh" {
  network_acl_id = aws_network_acl.bastion_acl.id
  rule_number    = 105
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "51.44.16.230/32"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "deny_ssh_other" {
  network_acl_id = aws_network_acl.bastion_acl.id
  rule_number    = 110
  protocol       = "tcp"
  rule_action    = "deny"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

# Allow all outbound traffic from Bastion
resource "aws_network_acl_rule" "allow_all_egress1" {
  network_acl_id = aws_network_acl.bastion_acl.id
  rule_number    = 120
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# Allow all inbound traffic for Bastion (General traffic like HTTP/HTTPS)
resource "aws_network_acl_rule" "allow_all_inboun1d" {
  network_acl_id = aws_network_acl.bastion_acl.id
  rule_number    = 130
  protocol       = "-1"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# Nextcloud ACL
resource "aws_network_acl" "nextcloud_acl" {
  vpc_id = aws_vpc.main.id
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id,
    aws_subnet.private_subnet_3.id
  ]

  tags = { Name = "${local.name}-nextcloud-acl" }
}

# Deny SSH (port 22) from the specific IP range (18.206.107.24/29) to the Nextcloud subnet
resource "aws_network_acl_rule" "deny_ssh_from_specific_ip" {
  network_acl_id = aws_network_acl.nextcloud_acl.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "deny"
  egress         = false
  cidr_block     = "18.206.107.24/29"
  from_port      = 22
  to_port        = 22
}

# Allow all inbound traffic (all ports and protocols) to the Nextcloud subnet
resource "aws_network_acl_rule" "allow_all_inbound" {
  network_acl_id = aws_network_acl.nextcloud_acl.id
  rule_number    = 110
  protocol       = "-1" # All protocols
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# Allow all outbound traffic for Nextcloud
resource "aws_network_acl_rule" "allow_all_egress" {
  network_acl_id = aws_network_acl.nextcloud_acl.id
  rule_number    = 120
  protocol       = "-1" # All protocols
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

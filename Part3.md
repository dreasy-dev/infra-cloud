[]: # Part3.md starts here:

### Somaire 
- [Infrastructure as Code](#infrastructure-as-code)
  - [Tree de l'infrastructure](#tree-de-linfrastructure)
    - [vpc.tf](#vpctf)
    - [subnets.tf](#subnetstf)
    - [route.tf](#routetf)
    - [outputs.tf](#outputstf)
    - [cli output](#cli-output)
    - [Destroy the infrastructure](#destroy-the-infrastructure)
- [Ajout du bastion, nextcloud et des security groups](#ajout-du-bastion-nextcloud-et-des-security-groups)
    - [outputs.tf](#outputstf)
    - [security_groups.tf](#security_groupstf)
    - [ec2.tf](#ec2tf)
    - [ssh.tf](#sshtf)
    - [acl.tf](#acltf)
    - [Commande avant le `terraform apply`](#commande-avant-le-terraform-apply)


# Infrastructure as Code

## Tree de l'infrastructure
```bash
users:~/environment/tp4.01 $ tree -a
.
├── .terraform
│   └── providers
│       └── registry.terraform.io
│           └── hashicorp
│               └── aws
│                   └── 5.74.0
│                       └── linux_amd64
│                           ├── LICENSE.txt
│                           └── terraform-provider-aws_v5.74.0_x5
├── .terraform.lock.hcl
├── locals.tf*
├── outputs.tf*
├── providers.tf*
├── route.tf*
├── subnets.tf*
├── terraform.tfstate
├── terraform.tfstate.backup
└── vpc.tf*

7 directories, 12 files

* = fichier crée/modifié
```

### vpc.tf
```bash
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags       = local.tags
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = local.tags
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = { Name = "${local.name}-public-route-table" })
}
```

### subnets.tf
```bash
#Public 1
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "${local.name}-public-subnet-1" })
}
#Public 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = true
  tags                    = { Name = "${local.name}-public-subnet-2" })
}
#Public 3
resource "aws_subnet" "public_subnet_3" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-north-1c"
  map_public_ip_on_launch = true
  tags                    = { Name = "${local.name}-public-subnet-3" })
}

#Private 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-north-1a"
  tags              = { Name = "${local.name}-private-subnet-1" })
}
#Private 2
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "eu-north-1b"
  tags              = { Name = "${local.name}-private-subnet-2" })
}
# Private 3
resource "aws_subnet" "private_subnet_3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "eu-north-1c"
  tags              = { Name = "${local.name}-private-subnet-3" })
}
```
locals.tf
```bash
users:~/environment/tp4.01 $ cat locals.tf 
locals {
  user = "mgilles"                    
  tp   = basename(abspath(path.root)) 
  name = "${local.user}-${local.tp}"  
  tags = {                            
    Name  = local.name
    Owner = local.user
  }
}
```

### route.tf
```bash
# Public route table
resource "aws_route_table_association" "public_subnet_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_subnet_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_subnet_3" {
  subnet_id      = aws_subnet.public_subnet_3.id
  route_table_id = aws_route_table.public.id
}



resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name}-private-route-table-1" })
}

resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name}-private-route-table-2" })
}

resource "aws_route_table" "private_3" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name}-private-route-table-3" })
}

# Private tabel association

resource "aws_route_table_association" "private_subnet_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_subnet_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_2.id
}

resource "aws_route_table_association" "private_subnet_3" {
  subnet_id      = aws_subnet.private_subnet_3.id
  route_table_id = aws_route_table.private_3.id
}
```
outputs.tf
```bash
# Output vpc id
output "vpc_id" {
  description = "ID du VPC créé"
  value       = aws_vpc.main.id
}
# Output public subnets
output "public_subnets" {
  description = "IDs des sous-réseaux publics"
  value       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id, aws_subnet.public_subnet_3.id]
}
# Output private subnets
output "private_subnets" {
  description = "IDs des sous-réseaux privés"
  value       = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id, aws_subnet.private_subnet_3.id]
}
```

### cli output
```bash 
 
users:~/environment/tp4.01 $ terraform apply
[...]
aws_vpc.main: Creating...
aws_vpc.main: Creation complete after 1s [id=vpc-02df59338c5627472]
aws_internet_gateway.gw: Creating...
aws_subnet.public_subnet_2: Creating...
aws_subnet.public_subnet_3: Creating...
aws_route_table.private_1: Creating...
aws_subnet.private_subnet_1: Creating...
aws_subnet.public_subnet_1: Creating...
aws_route_table.private_3: Creating...
aws_route_table.private_2: Creating...
aws_subnet.private_subnet_3: Creating...
aws_subnet.private_subnet_2: Creating...
aws_route_table.private_1: Creation complete after 1s [id=rtb-045293054da2a27d7]
aws_route_table.private_2: Creation complete after 1s [id=rtb-01724fa2458200c31]
aws_internet_gateway.gw: Creation complete after 1s [id=igw-0ee4b3978b16043f9]
aws_route_table.public: Creating...
aws_route_table.private_3: Creation complete after 1s [id=rtb-0a611286f634257bd]
aws_subnet.private_subnet_1: Creation complete after 1s [id=subnet-04f42ba6eb7c9f620]
aws_route_table_association.private_subnet_1: Creating...
aws_subnet.private_subnet_2: Creation complete after 1s [id=subnet-04dbc1133b54d2b80]
aws_route_table_association.private_subnet_2: Creating...
aws_subnet.private_subnet_3: Creation complete after 2s [id=subnet-087ac67e3b4d7a80e]
aws_route_table_association.private_subnet_3: Creating...
aws_route_table_association.private_subnet_1: Creation complete after 1s [id=rtbassoc-03a29d91adfeb032b]
aws_route_table_association.private_subnet_2: Creation complete after 1s [id=rtbassoc-03ca18e726e661896]
aws_route_table_association.private_subnet_3: Creation complete after 0s [id=rtbassoc-0d20b490425a9eb1d]
aws_route_table.public: Creation complete after 1s [id=rtb-08fdae2d41cf1126a]
aws_subnet.public_subnet_2: Still creating... [10s elapsed]
aws_subnet.public_subnet_3: Still creating... [10s elapsed]
aws_subnet.public_subnet_1: Still creating... [10s elapsed]
aws_subnet.public_subnet_1: Creation complete after 11s [id=subnet-0bcaca7f0b9d9f2bc]
aws_route_table_association.public_subnet_1: Creating...
aws_subnet.public_subnet_3: Creation complete after 12s [id=subnet-07d92ad97b5536d63]
aws_route_table_association.public_subnet_3: Creating...
aws_subnet.public_subnet_2: Creation complete after 12s [id=subnet-085f3bdd35d01944d]
aws_route_table_association.public_subnet_2: Creating...
aws_route_table_association.public_subnet_1: Creation complete after 0s [id=rtbassoc-015b150639bc4f645]
aws_route_table_association.public_subnet_3: Creation complete after 0s [id=rtbassoc-023d0d4527291abd2]
aws_route_table_association.public_subnet_2: Still creating... [10s elapsed]
aws_route_table_association.public_subnet_2: Still creating... [20s elapsed]
aws_route_table_association.public_subnet_2: Creation complete after 23s [id=rtbassoc-0db5cc417a08b8666]

Apply complete! Resources: 18 added, 0 changed, 0 destroyed.

Outputs:

private_subnets = [
  "subnet-04f42ba6eb7c9f620",
  "subnet-04dbc1133b54d2b80",
  "subnet-087ac67e3b4d7a80e",
]
public_subnets = [
  "subnet-0bcaca7f0b9d9f2bc",
  "subnet-085f3bdd35d01944d",
  "subnet-07d92ad97b5536d63",
]
vpc_id = "vpc-02df59338c5627472"

```
## Destroy the infrastructure
```bash
users:~/environment/tp4.01 $ terraform destroy
[...]
yes
Destroy complete! Resources: 18 destroyed.
```

# Ajout du bastion, nextcloud et des security groups

### outputs.tf
```bash
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
```

### security_groups.tf
```bash
resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name}-bastion-sg" })

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["195.7.117.146/32"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["51.44.16.230/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "private_app_sg" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name}-private-app-sg" })

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
}
```

### ec2.tf
```bash 

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]  # This is the owner ID for Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["buntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"] 
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t4g.micro"
  key_name      = aws_key_pair.bastion.key_name
  subnet_id     = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  
  tags = { Name = "${local.name}-bastion-instance" })
}

resource "aws_instance" "nextcloud" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t4g.micro"
  key_name      = aws_key_pair.nextcloud.key_name
  subnet_id     = aws_subnet.private_subnet_1.id
  vpc_security_group_ids = [aws_security_group.private_app_sg.id]

  tags = { Name = "${local.name}-nextcloud" })
}
```

### ssh.tf
```bash 
resource "aws_key_pair" "bastion" {
  key_name   = "${local.name}-bastion"
  public_key = file("ssh/bastion.pub")
}
resource "aws_key_pair" "nextcloud" {
  key_name   = "${local.name}-nextcloud"
  public_key = file("ssh/nextcloud.pub")
}
```

### acl.tf
```bash
# Bastion ACL
resource "aws_network_acl" "bastion_acl" {
  vpc_id = aws_vpc.main.id
  subnet_ids = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id,
    aws_subnet.public_subnet_3.id
  ]

  tags = { Name = "${local.name}-bastion-acl" })
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

resource "aws_network_acl_rule" "allow_all_egress" {
  network_acl_id = aws_network_acl.bastion_acl.id
  rule_number    = 120
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "allow_all_inbound" {
  network_acl_id = aws_network_acl.bastion_acl.id
  rule_number    = 130
  protocol       = "-1"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
}

# Nextcloud ACL
resource "aws_network_acl" "nextcloud_acl" {
  vpc_id = aws_vpc.main.id
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id,
    aws_subnet.private_subnet_3.id
  ]

  tags = { Name = "${local.name}-nextcloud-acl" })
}


resource "aws_network_acl_rule" "allow_private_subnets_ssh" {
  network_acl_id = aws_network_acl.nextcloud_acl.id  
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "10.0.0.0/16"  
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "allow_all_egress_nextcloud" {
  network_acl_id = aws_network_acl.nextcloud_acl.id
  rule_number    = 110
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
}

```

### Commande avant le `terraform apply`
Avant de lancer le `terraform apply`, il faut créer la paire de clé ssh `bastion` dans le dossier `ssh` avec la commande 
```bash
mkdir -p ssh
ssh-keygen -t rsa -b 2048 -C "tp04-ex02-bastion" -f ssh/bastion
ssh-keygen -t rsa -b 2048 -C "tp04-ex02-nextcloud" -f ssh/nextcloud
```


resource "aws_key_pair" "bastion" {
  key_name   = "${local.name}-bastion"
  public_key = file("ssh/bastion.pub")
}
resource "aws_key_pair" "nextcloud" {
  key_name   = "${local.name}-nextcloud"
  public_key = file("ssh/nextcloud.pub")
}

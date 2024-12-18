resource "time_static" "oui" {}


resource "aws_efs_file_system" "nextcloud_efs" {
  creation_token   = "nextcloud-efs-${(time_static.oui.rfc3339)}"
  performance_mode = "generalPurpose"
  encrypted        = true
  tags = {
    Name = "${local.name}-nextcloud-efs"
  }
}

resource "aws_efs_mount_target" "nextcloud_efs_mt_1" {
  file_system_id  = aws_efs_file_system.nextcloud_efs.id
  subnet_id       = aws_subnet.private_subnet_1.id
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_mount_target" "nextcloud_efs_mt_2" {
  file_system_id  = aws_efs_file_system.nextcloud_efs.id
  subnet_id       = aws_subnet.private_subnet_2.id
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_mount_target" "nextcloud_efs_mt_3" {
  file_system_id  = aws_efs_file_system.nextcloud_efs.id
  subnet_id       = aws_subnet.private_subnet_3.id
  security_groups = [aws_security_group.efs_sg.id]
}
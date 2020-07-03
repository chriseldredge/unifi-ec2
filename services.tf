resource "aws_instance" "unifi" {
  ami = var.ami
  instance_type = var.instance_type
  availability_zone = var.availability_zone
  key_name = aws_key_pair.unifi.key_name
  security_groups = [
    aws_security_group.unifi.name,
    aws_security_group.nginx.name,
    aws_security_group.ssh.name
  ]
  ebs_optimized = true
  user_data = templatefile("files/ec2-start.tpl", {
    server_name = var.server_name,
    admin_email = var.admin_email
  })
}

resource "aws_ebs_volume" "unifi-data" {
  availability_zone = var.availability_zone
  size              = 5
  type              = "standard"
}

resource "aws_volume_attachment" "unifi-data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.unifi-data.id
  instance_id = aws_instance.unifi.id
}

resource "aws_eip" "unifi-public" {
  instance = aws_instance.unifi.id
}

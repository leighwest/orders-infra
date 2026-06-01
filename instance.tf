resource "aws_instance" "orders" {
  ami                         = "ami-0a40c45ee943b3cfa"
  instance_type               = "t4g.small"
  associate_public_ip_address = true

  tags = {
    Name = "orders-server"
  }

  vpc_security_group_ids = [aws_security_group.default.id]
  user_data              = data.cloudinit_config.instance-bootstrap.rendered
  key_name               = "orders"
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
}

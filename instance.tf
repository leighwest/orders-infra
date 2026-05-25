resource "aws_instance" "orders" {
  ami                         = "ami-0fddd1724e3df67ed"
  instance_type               = "t3.small"
  associate_public_ip_address = true

  tags = {
    Name = "orders-server"
  }

  vpc_security_group_ids = [aws_security_group.default.id]
  user_data              = data.cloudinit_config.instance-bootstrap.rendered
  key_name               = "orders"
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
}

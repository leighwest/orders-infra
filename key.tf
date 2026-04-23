resource "aws_key_pair" "keypair" {
  key_name   = "orders"
  public_key = file(var.PATH_TO_PUBLIC_KEY)
}

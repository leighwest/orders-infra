data "cloudinit_config" "instance-bootstrap" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = templatefile("scripts/init.cfg", {})
  }
}

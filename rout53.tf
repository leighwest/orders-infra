# route53.tf

resource "aws_route53_zone" "leighwest_dev" {
  name = "leighwest.dev"
}

# --- A Records ---

resource "aws_route53_record" "cupcakes_api" {
  zone_id = aws_route53_zone.leighwest_dev.zone_id
  name    = "cupcakes-api.leighwest.dev"
  type    = "A"
  ttl     = 60
  records = ["16.26.30.45"]
}

resource "aws_route53_record" "www_cupcakes_api" {
  zone_id = aws_route53_zone.leighwest_dev.zone_id
  name    = "www.cupcakes-api.leighwest.dev"
  type    = "A"
  ttl     = 300
  records = ["16.26.30.45"]
}

resource "aws_route53_record" "instance_starter" {
  zone_id = aws_route53_zone.leighwest_dev.zone_id
  name    = "instance-starter.leighwest.dev"
  type    = "A"
  ttl     = 300
  records = ["139.84.203.187"]
}

# --- Apex alias (portfolio site → Netlify) ---

resource "aws_route53_record" "apex" {
  zone_id = aws_route53_zone.leighwest_dev.zone_id
  name    = "leighwest.dev"
  type    = "A"
  ttl     = 300
  records = ["75.2.60.5", "99.83.190.102"]
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.leighwest_dev.zone_id
  name    = "www.leighwest.dev"
  type    = "CNAME"
  ttl     = 300
  records = ["distracted-knuth-2af9c0.netlify.app"]
}

# --- SES DKIM CNAMEs ---

resource "aws_route53_record" "ses_dkim_1" {
  zone_id = aws_route53_zone.leighwest_dev.zone_id
  name    = "amawpplytmno334m2gy2ddc5uwjevdqn._domainkey.leighwest.dev"
  type    = "CNAME"
  ttl     = 300
  records = ["amawpplytmno334m2gy2ddc5uwjevdqn.dkim.amazonses.com"]
}

resource "aws_route53_record" "ses_dkim_2" {
  zone_id = aws_route53_zone.leighwest_dev.zone_id
  name    = "bfbrtub3i24rdv7ha4swt2pksm7cskat._domainkey.leighwest.dev"
  type    = "CNAME"
  ttl     = 300
  records = ["bfbrtub3i24rdv7ha4swt2pksm7cskat.dkim.amazonses.com"]
}

resource "aws_route53_record" "ses_dkim_3" {
  zone_id = aws_route53_zone.leighwest_dev.zone_id
  name    = "g6a352rdkue27yibfscwgjptfyiufhzt._domainkey.leighwest.dev"
  type    = "CNAME"
  ttl     = 300
  records = ["g6a352rdkue27yibfscwgjptfyiufhzt.dkim.amazonses.com"]
}

# --- DMARC ---

resource "aws_route53_record" "dmarc" {
  zone_id = aws_route53_zone.leighwest_dev.zone_id
  name    = "_dmarc.leighwest.dev"
  type    = "TXT"
  ttl     = 300
  records = ["v=DMARC1; p=none;"]
}

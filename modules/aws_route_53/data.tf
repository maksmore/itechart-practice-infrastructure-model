data "aws_route53_zone" "my_domain" {
  name         = var.dns_name
  private_zone = false
}

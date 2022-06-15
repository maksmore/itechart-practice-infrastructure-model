resource "aws_acm_certificate" "cert" {
  domain_name       = var.env == "dev" || var.env == "test" ? "${var.env}.${var.dns_name}" : var.dns_name
  validation_method = "DNS"

  subject_alternative_names = ["*.${var.dns_name}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "my_cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.my_cert : record.fqdn]
}

resource "aws_route53_record" "domain_name" {
  zone_id = data.aws_route53_zone.my_domain.zone_id
  name    = var.env == "dev" || var.env == "test" ? "${var.env}.${var.dns_name}" : var.dns_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "my_cert" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.my_domain.zone_id
}

resource "aws_route53_record" "www-env" {
  count   = var.www ? 1 : 0
  zone_id = data.aws_route53_zone.my_domain.zone_id
  name    = "www"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "backend" {
  zone_id = data.aws_route53_zone.my_domain.zone_id
  name    = "${var.env}-api"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
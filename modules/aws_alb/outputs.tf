output "backend_tg_arn" {
  value = aws_lb_target_group.backend_tg.arn
}

output "frontend_tg_arn" {
  value = aws_lb_target_group.frontend_tg.arn
}

output "facing_alb_url" {
  value = aws_lb.frontend.dns_name
}

output "facing_alb_zone_id" {
  value = aws_lb.frontend.zone_id
}

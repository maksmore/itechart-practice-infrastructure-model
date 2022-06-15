variable "vpc_main_id" {
  type = string
}

variable "env" {
  type = string
}

variable "alb_security_group_id" {
  type = string
}

variable "internal_alb_security_group_id" {
  type = string
}

variable "main_vpc_created" {
  type = string
}

variable "alb_sg_created" {
  type = string
}

variable "facing_lb_name" {
  type = string
}

variable "alb_sg_name" {
  type = string
}

variable "pub_subnet_ids" {
  type = list(any)
}

variable "acm_cert_validation_cert_arn" {
  type = string
}

variable "domain_name" {
  type = string
}

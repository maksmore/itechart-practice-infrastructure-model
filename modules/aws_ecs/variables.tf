variable "app_name" {
  default = "practice_project"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type = string
}
variable "env" {
  type = string
}

variable "instance_profile" {
  type = string
}

variable "ec2_sg_id" {
  type = string
}

variable "pub_subnet_ids" {
  type = list(any)
}

variable "db_subnet_ids" {
  type = list(any)
}

variable "asg_name" {
  default = "ASG"
}

variable "db_sg_id" {
  type = string
}

variable "public_key" {
  default = "ssh-rsa AAAAB3NzaC1... maksmore@local"
}

variable "availability_zones_available_names" {
  type = list(any)
}

variable "ecs_task_execution_role" {
  type = string
}

variable "ecs_task_role_arn" {
  type = string
}

variable "aws_region_current" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "spot_price" {
  type = string
}

variable "internal_lb_name" {
  type    = string
  default = "Backend-ALB"
}

variable "facing_alb_url" {
  type = string
}

variable "backend_tg_arn" {
  type = string
}

variable "frontend_tg_arn" {
  type = string
}

variable "domain_name" {
  type = string
}

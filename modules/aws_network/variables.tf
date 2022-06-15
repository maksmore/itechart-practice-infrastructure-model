variable "vpc_cidr" {
  type = string
}

variable "pub_subnet_cidrs" {
  type = list(any)
}

variable "database_subnet_cidrs" {
  type = list(any)
}
variable "app_name" {
  default = "Practice_Project"
}
variable "env" {
  type = string
}

variable "ec2_name_sg" {
  default = "EC2"
}

variable "db_name_sg" {
  default = "Database"
}

variable "alb_sg_name" {
  type = string
}

variable "allow_ports" {
  description = "List Of Ports To Open For WebServer:"
  type        = list(any)
  default     = ["5432"]
}

variable "allow_alb_ports" {
  description = "List of Ports To Open For Facing Load Balancer"
  type        = list(any)
  default     = ["80", "443", "3000"]
}

variable "allow_internal_alb_ports" {
  description = "List of Ports To Open For Internal Load Balancer"
  type        = list(any)
  default     = ["80", "3000"]
}

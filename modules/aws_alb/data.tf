data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = [var.env]
  }
  
  depends_on = [var.main_vpc_created]
}

data "aws_subnets" "pub_subnets" {
  filter {
    name   = "tag:Name"
    values = ["${var.env}-Pub-Subnet"]
  }
}

data "aws_subnet" "pub_subnet" {
  for_each = toset(data.aws_subnets.pub_subnets.ids)
  id       = each.value
}

data "aws_security_group" "alb_sg" {
  filter {
    name   = "tag:Name"
    values = ["${var.env}-ALB-SG"]
  }
  depends_on = [var.alb_sg_created]
}

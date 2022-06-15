output "availability_zones_available_names" {
  value = data.aws_availability_zones.available.names
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "pub_subnet_ids" {
  value = aws_subnet.pub_subnet[*].id
}

output "db_subnet_ids" {
  value = aws_subnet.database_subnet[*].id
}

output "ec2_sg_id" {
  value = aws_security_group.ec2_sg.id
}

output "db_sg_id" {
  value = aws_security_group.db_sg.id
}

output "main_vpc_created" {
  value = aws_vpc.main.id
}

output "alb_sg_created" {
  value = aws_security_group.alb_sg.id
}

output "internal_alb_sg_created" {
  value = aws_security_group.internal_alb_sg.id
}

output "alb_sg_name" {
  value = aws_security_group.alb_sg.name
}

output "pub_subnets" {
  value = aws_subnet.pub_subnet
}

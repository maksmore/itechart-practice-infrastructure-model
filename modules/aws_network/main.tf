# -------------------------------------------------------------------------------------|

resource "aws_vpc" "main" {
  #ts:skip=AWS.VPC.Logging.Medium.0470 need to skip
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.env
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = var.app_name
  }
  depends_on = [aws_vpc.main]
}

resource "aws_subnet" "pub_subnet" {
  count                   = length(var.pub_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.pub_subnet_cidrs, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env}-Pub-Subnet"
  }
}

resource "aws_subnet" "database_subnet" {
  count             = length(var.pub_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.database_subnet_cidrs, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.env}-Database-Subnet"
  }
}

resource "aws_route_table" "pub_route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    "Name" = "${var.env}-Public-Route"
  }
}

resource "aws_route_table_association" "pub" {
  count          = length(aws_subnet.pub_subnet)
  subnet_id      = aws_subnet.pub_subnet[count.index].id
  route_table_id = aws_route_table.pub_route.id

}

resource "aws_route_table" "database_route" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Database-Route-Table"
  }
}

resource "aws_route_table_association" "database" {
  count          = length(aws_subnet.database_subnet)
  subnet_id      = aws_subnet.database_subnet[count.index].id
  route_table_id = aws_route_table.database_route.id
}

# ------------------------------ Security Groups ---------------------------------------|

resource "aws_security_group" "ec2_sg" {
  name        = var.ec2_name_sg
  description = "Allows PostgreSQL TCP traffic and other necessary ports"
  vpc_id      = aws_vpc.main.id
  dynamic "ingress" {
    for_each = {
      "5432" = {
        security_groups = [aws_security_group.db_sg.id]
      }
      # "22" = {
      #   cidr_blocks = ["0.0.0.0/0"]
      # }
 
      "AllPorts" = {
        security_groups = [aws_security_group.alb_sg.id]
        from_port       = 0
        to_port         = 65535
      }
      "BackendPorts" = {
        security_groups = [aws_security_group.internal_alb_sg.id]
        from_port       = 0
        to_port         = 65535
      }
    }

    content {
      from_port       = lookup(ingress.value, "from_port", ingress.key)
      to_port         = lookup(ingress.value, "to_port", ingress.key)
      protocol        = "tcp"
      cidr_blocks     = lookup(ingress.value, "cidr_blocks", null)
      security_groups = lookup(ingress.value, "security_groups", null)
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.env}-${var.ec2_name_sg}-SG"
  }
}

resource "aws_security_group" "db_sg" {
  name        = var.db_name_sg
  description = "Allows PostgreSQL TCP traffic"
  vpc_id      = aws_vpc.main.id
  dynamic "ingress" {
    for_each = var.allow_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = [aws_vpc.main.cidr_block]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.env}-${var.db_name_sg}-SG"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = var.alb_sg_name
  description = "Allows HTTP, HTTPS traffic"
  vpc_id      = aws_vpc.main.id
  dynamic "ingress" {
    for_each = var.allow_alb_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-ALB-SG"
  }
}

# ------------------------- Launch Configuration & ASG Creation ----------------------------|

resource "aws_key_pair" "pub_key" {
  key_name_prefix   = "id_rsa"
  public_key = var.public_key
}

data "template_file" "user_data" {
  template = file("./templates/script.sh.tpl")

  vars = {
    "env" = var.env
  }
}

resource "aws_launch_configuration" "ecs_launch_config" {
  #ts:skip=AC-AW-CA-LC-H-0439 need to skip it
  name_prefix          = "App_in_ECS-"
  image_id             = data.aws_ami.ecs.id
  iam_instance_profile = var.instance_profile
  security_groups      = [var.ec2_sg_id]
  user_data            = data.template_file.user_data.rendered # file("${path.module}/script.sh")
  instance_type        = var.instance_type
  spot_price           = var.spot_price
  key_name             = aws_key_pair.pub_key.key_name
  enable_monitoring    = true
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  # current_az = data.aws_availability_zone.current.name
  az_list = join(", ", data.aws_availability_zones.available.names)
}

resource "aws_autoscaling_group" "ecs_asg" {
  #ts:skip=AC-AW-CA-LC-H-0439 need to skip it
  name                 = "${var.env}-${var.asg_name}"
  vpc_zone_identifier  = [var.pub_subnet_ids[0], var.pub_subnet_ids[1], var.pub_subnet_ids[2]]
  launch_configuration = aws_launch_configuration.ecs_launch_config.name
  target_group_arns    = [var.backend_tg_arn, var.frontend_tg_arn]

  desired_capacity          = 2
  min_size                  = 2
  max_size                  = 4
  health_check_grace_period = 300
  health_check_type         = "EC2"

  dynamic "tag" {
    for_each = {
      Name              = "Practice_Project"
      Owner             = "maksmore"
      Environment       = "${var.env}"
      AmazonECSManaged  = true
      Availability_Zone = local.az_list
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [aws_db_instance.postgres_rds]
}

resource "aws_ecs_cluster_capacity_providers" "practice_project" {
  cluster_name = aws_ecs_cluster.app_cluster.name

  capacity_providers = [aws_ecs_capacity_provider.practice_project_provider.name]

  default_capacity_provider_strategy {
    base              = 4
    weight            = var.env == "dev" ? 100 : 99
    capacity_provider = aws_ecs_capacity_provider.practice_project_provider.name
  }
}

resource "aws_ecs_capacity_provider" "practice_project_provider" {
  name = "${var.env}_practice_project_provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_asg.arn
    managed_termination_protection = "DISABLED"
  }
}

resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.env}-ECS-Cluster"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.env}-env"
  }
}

resource "aws_cloudwatch_log_group" "backend_task_logs" {
  name = "${var.env}-backend-logs"
}

resource "aws_cloudwatch_log_group" "frontend_task_logs" {
  name = "${var.env}-frontend-logs"
}

data "template_file" "backend_container_definition" {
  template = file("./templates/backend_container.json.tpl")

  vars = {
    "backend_image" = var.env == "dev" ? "233817511251.dkr.ecr.us-east-1.amazonaws.com/dev_practice_project_backend:latest" : "233817511251.dkr.ecr.us-east-1.amazonaws.com/practice_project_backend:latest"
    "domain_name"      = var.env == "dev" ? "${var.env}.${var.domain_name}" : var.domain_name
    "db_host"          = aws_db_instance.postgres_rds.address
    "log_group_name"   = aws_cloudwatch_log_group.backend_task_logs.name
    "log_group_region" = var.aws_region_current
  }
}

data "template_file" "frontend_container_definition" {
  template = file("./templates/frontend_container.json.tpl")

  vars = {
    "frontend_image" = var.env == "dev" ? "233817511251.dkr.ecr.us-east-1.amazonaws.com/dev_practice_project_frontend:latest" : "233817511251.dkr.ecr.us-east-1.amazonaws.com/practice_project_frontend:latest"
    "backend_path"     = "${var.env}-api.${var.domain_name}"
    "domain_name"      = var.env == "dev" ? "${var.env}.${var.domain_name}" : var.domain_name
    "log_group_name"   = aws_cloudwatch_log_group.frontend_task_logs.name
    "log_group_region" = var.aws_region_current
  }
}

resource "aws_ecs_task_definition" "backend_task_definition" {
  family                   = "${var.env}_practice_project_backend"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  container_definitions    = data.template_file.backend_container_definition.rendered
  task_role_arn            = var.ecs_task_role_arn
  execution_role_arn       = var.ecs_task_execution_role

  depends_on = [aws_db_instance.postgres_rds]
}

resource "aws_ecs_task_definition" "frontend_task_definition" {
  family                   = "${var.env}_practice_project_frontend"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  container_definitions    = data.template_file.frontend_container_definition.rendered
  task_role_arn            = var.ecs_task_role_arn
  execution_role_arn       = var.ecs_task_execution_role

}

resource "aws_ecs_service" "backend" {
  name                               = "${var.env}_backend"
  cluster                            = aws_ecs_cluster.app_cluster.id
  task_definition                    = aws_ecs_task_definition.backend_task_definition.id
  desired_count                      = 2
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  scheduling_strategy                = "REPLICA"

  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }

  deployment_controller {
    type = "ECS"
  }

  load_balancer {
    target_group_arn = var.backend_tg_arn
    container_name   = "${var.env}_backend"
    container_port   = 3000
  }
  tags = {
    "Role" = "Backend"
  }

  depends_on = [aws_db_instance.postgres_rds]
}

resource "aws_appautoscaling_target" "backend_target" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${var.env}-ECS-Cluster/${var.env}_backend"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  role_arn           = var.ecs_task_role_arn
}

resource "aws_appautoscaling_policy" "backend_target_cpu" {
  name               = "${var.env}-app-scaling-policy-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend_target.resource_id
  scalable_dimension = aws_appautoscaling_target.backend_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 60
  }
  depends_on = [aws_appautoscaling_target.backend_target]
}
resource "aws_appautoscaling_policy" "backend_target_memory" {
  name               = "${var.env}-app-scaling-policy-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend_target.resource_id
  scalable_dimension = aws_appautoscaling_target.backend_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80
  }
  depends_on = [aws_appautoscaling_target.backend_target]
}

resource "aws_ecs_service" "frontend" {
  name                               = "${var.env}_frontend"
  cluster                            = aws_ecs_cluster.app_cluster.id
  task_definition                    = aws_ecs_task_definition.frontend_task_definition.id
  desired_count                      = 2
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  scheduling_strategy                = "REPLICA"

  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [${data.aws_availability_zones.available.names[0]}, ${data.aws_availability_zones.available.names[1]}, ${data.aws_availability_zones.available.names[2]}]"
  }

  deployment_controller {
    type = "ECS"
  }

  load_balancer {
    target_group_arn = var.frontend_tg_arn
    container_name   = "${var.env}_frontend"
    container_port   = 3001
  }
  tags = {
    "Role" = "Frontend"
  }

}

resource "aws_appautoscaling_target" "frontend_target" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${var.env}-ECS-Cluster/${var.env}_frontend"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  role_arn           = var.ecs_task_role_arn
}

resource "aws_appautoscaling_policy" "frontend_target_cpu" {
  name               = "${var.env}-application-scaling-policy-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.frontend_target.resource_id
  scalable_dimension = aws_appautoscaling_target.frontend_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.frontend_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 60
  }
  depends_on = [aws_appautoscaling_target.frontend_target]
}

resource "aws_appautoscaling_policy" "frontend_target_memory" {
  name               = "${var.env}-application-scaling-policy-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.frontend_target.resource_id
  scalable_dimension = aws_appautoscaling_target.frontend_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.frontend_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80
  }
  depends_on = [aws_appautoscaling_target.frontend_target]
}

resource "aws_ssm_parameter" "rds_password" {
  name        = "/${var.env}/postgres"
  description = "Master Password for RDS PostgreSQL"
  type        = "SecureString"
  value       = var.db_password
}

resource "aws_db_subnet_group" "db_subnet" {
  name = "${var.env}-practice_project"
  subnet_ids  = [var.db_subnet_ids[0], var.db_subnet_ids[1], var.db_subnet_ids[2]]

  tags = {
    Name = "DB_Subnet_Group"
  }
}

resource "aws_db_instance" "postgres_rds" {
  identifier             = "${var.env}-rds"
  allocated_storage      = 10
  engine                 = "postgres"
  engine_version         = "12.10"
  instance_class         = "db.t2.micro"
  db_name                = var.db_name
  username               = "postgres"
  password               = aws_ssm_parameter.rds_password.value
  parameter_group_name   = "default.postgres12"
  skip_final_snapshot    = true
  apply_immediately      = true
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [var.db_sg_id]
  tags = {
    "Name" = "PostgreSQL_Database"
  }
}
provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "itechart-practice-terraform-state"
    key    = "dev/application/terraform.tfstate"
    region = "eu-west-1"
  }
}

module "vpc-dev" {
  source                = "../modules/aws_network"
  env                   = "dev"
  vpc_cidr              = "10.1.0.0/16"
  pub_subnet_cidrs      = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  database_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
  alb_sg_name           = "Facing-ALB-SG"
}

module "iam-dev" {
  source = "../modules/aws_iam"
  env    = "dev"
}

module "ecs-dev" {
  source                             = "../modules/aws_ecs"
  env                                = "dev"
  db_password                        = "your_password"
  db_name                            = "practice_project"
  instance_type                      = "t3a.xlarge"
  spot_price                         = "0.0627"
  instance_profile                   = module.iam-dev.instance_profile
  ec2_sg_id                          = module.vpc-dev.ec2_sg_id
  pub_subnet_ids                     = module.vpc-dev.pub_subnet_ids
  db_subnet_ids                      = module.vpc-dev.db_subnet_ids
  db_sg_id                           = module.vpc-dev.db_sg_id
  ecs_task_execution_role            = module.iam-dev.ecs_task_execution_role
  ecs_task_role_arn                  = module.iam-dev.ecs_task_role_arn
  aws_region_current                 = module.ecs-dev.aws_region_current
  availability_zones_available_names = module.vpc-dev.availability_zones_available_names
  facing_alb_url                     = module.alb-dev.facing_alb_url
  backend_tg_arn                     = module.alb-dev.backend_tg_arn
  frontend_tg_arn                    = module.alb-dev.frontend_tg_arn
  domain_name                        = "your_domain"
}

module "alb-dev" {
  source                         = "../modules/aws_alb"
  env                            = "dev"
  domain_name                    = "your_domain"
  vpc_main_id                    = module.vpc-dev.main_vpc_created
  pub_subnet_ids                 = module.vpc-dev.pub_subnets
  alb_security_group_id          = module.vpc-dev.alb_sg_created
  main_vpc_created               = module.vpc-dev.main_vpc_created
  alb_sg_created                 = module.vpc-dev.alb_sg_created
  facing_lb_name                 = "ALB"
  alb_sg_name                    = module.vpc-dev.alb_sg_name
  acm_cert_validation_cert_arn   = module.route53-dev.acm_cert_validation_cert_arn
}

module "route53-dev" {
  source       = "../modules/aws_route_53"
  dns_name     = "your_domain"
  alb_dns_name = module.alb-dev.facing_alb_url
  alb_zone_id  = module.alb-dev.facing_alb_zone_id
  domain_env   = true
  www          = false
  env          = "dev"
}

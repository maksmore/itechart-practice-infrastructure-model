provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "itechart-practice-terraform-state"
    key    = "prod/application/terraform.tfstate"
    region = "eu-west-1"
  }
}

module "vpc-prod" {
  source                = "../modules/aws_network"
  env                   = "prod"
  vpc_cidr              = "172.16.0.0/16"
  pub_subnet_cidrs      = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  database_subnet_cidrs = ["172.16.11.0/24", "172.16.12.0/24", "172.16.13.0/24"]
  alb_sg_name           = "Facing-ALB-SG"
}

module "iam-prod" {
  source = "../modules/aws_iam"
  env    = "prod"
}

module "ecs-prod" {
  source                             = "../modules/aws_ecs"
  env                                = "prod"
  db_password                        = "your_password"
  db_name                            = "practice_project"
  instance_type                      = "t3a.xlarge"
  spot_price                         = "0.0627"
  instance_profile                   = module.iam-prod.instance_profile
  ec2_sg_id                          = module.vpc-prod.ec2_sg_id
  pub_subnet_ids                     = module.vpc-prod.pub_subnet_ids
  db_subnet_ids                      = module.vpc-prod.db_subnet_ids
  db_sg_id                           = module.vpc-prod.db_sg_id
  ecs_task_execution_role            = module.iam-prod.ecs_task_execution_role
  ecs_task_role_arn                  = module.iam-prod.ecs_task_role_arn
  aws_region_current                 = module.ecs-prod.aws_region_current
  availability_zones_available_names = module.vpc-prod.availability_zones_available_names
  facing_alb_url                     = module.alb-prod.facing_alb_url
  backend_tg_arn                     = module.alb-prod.backend_tg_arn
  frontend_tg_arn                    = module.alb-prod.frontend_tg_arn
  domain_name                        = "your_domain"
}

module "alb-prod" {
  source                         = "../modules/aws_alb"
  env                            = "prod"
  domain_name                    = "your_domain"
  vpc_main_id                    = module.vpc-prod.main_vpc_created
  pub_subnet_ids                 = module.vpc-prod.pub_subnets
  alb_security_group_id          = module.vpc-prod.alb_sg_created
  main_vpc_created               = module.vpc-prod.main_vpc_created
  alb_sg_created                 = module.vpc-prod.alb_sg_created
  facing_lb_name                 = "ALB"
  alb_sg_name                    = module.vpc-prod.alb_sg_name
  acm_cert_validation_cert_arn   = module.route53-prod.acm_cert_validation_cert_arn
}

module "route53-prod" {
  source       = "../modules/aws_route_53"
  dns_name     = "your_domain"
  alb_dns_name = module.alb-prod.facing_alb_url
  alb_zone_id  = module.alb-prod.facing_alb_zone_id
  domain_env   = false
  www          = true
  env          = "prod"
}

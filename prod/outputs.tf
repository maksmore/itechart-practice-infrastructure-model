output "vpc_id" {
  value = module.vpc-prod.vpc_id
}

output "iam_instance_profile" {
  value = module.iam-prod.instance_profile
}

output "database_address" {
  value = module.ecs-prod.database_address
}

output "instance_profile" {
  value = aws_iam_instance_profile.app_iam_role.name
}

output "ecs_task_execution_role" {
  value = aws_iam_role.task_execution_role.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.app_iam_role.arn
}
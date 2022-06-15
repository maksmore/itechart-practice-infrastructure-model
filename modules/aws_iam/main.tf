# ----------------------------- IAM Role Policies ------------------------------------------|

resource "aws_iam_policy" "task_execution_role_policy" {
  name        = "${var.env}-task-exec-role-policy"
  path        = "/"
  description = "Allow retrieving of images managed by ec2 and adding to logs"
  policy      = file("./templates/ecs/task-exec-role.json")
}

resource "aws_iam_role" "task_execution_role" {
  name_prefix        = "${var.env}-task-execution-role-"
  assume_role_policy = file("./templates/ecs/assume-role-policy.json")
}


resource "aws_iam_role_policy_attachment" "task_execution_role" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.task_execution_role_policy.arn
}

resource "aws_iam_role" "app_iam_role" {
  name_prefix        = "${var.app_name}-task-"
  assume_role_policy = file("./templates/ecs/assume-role-policy.json")
  tags = {
    Name = "${var.app_name}-iam-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_app_iam_role" {
  role       = aws_iam_role.app_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm_ecs_app_iam_role" {
  role       = aws_iam_role.app_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "app_iam_role" {
  role       = aws_iam_role.app_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs-autoscale" {
  role       = aws_iam_role.app_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}


resource "aws_iam_role_policy_attachment" "ssm_task_execution_role" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app_iam_role" {
  name_prefix = "${var.app_name}-task-"
  role        = aws_iam_role.app_iam_role.name
}

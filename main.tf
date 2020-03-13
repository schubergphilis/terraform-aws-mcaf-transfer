locals {
  user_name_ssh_pub_keys = flatten([
    for transfer_user_key, transfer_user in var.transfer_users : [
      for ssh_pub_key in transfer_user.ssh_pub_keys : {
        user_name   = transfer_user.user_name
        role_policy = transfer_user.role_policy
        ssh_pub_key = ssh_pub_key
      }
    ]
  ])
  default_transfer_user_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowFullAccesstoS3",
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

resource "aws_iam_role" "default" {
  name               = var.name
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "transfer.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = var.name
  policy_arn = var.logging_policy
  depends_on = [aws_iam_role.default]
}

resource "aws_transfer_server" "default" {
  identity_provider_type = "SERVICE_MANAGED"
  logging_role           = aws_iam_role.default.arn
  tags                   = var.tags
  endpoint_type          = upper(var.endpoint_type)
  depends_on             = [aws_iam_role.default]

  dynamic "endpoint_details" {
    for_each = upper(var.endpoint_type) != "PUBLIC" ? list(1) : []
    content {
      vpc_endpoint_id = var.vpc_endpoint_id
    }
  }
}

resource "aws_iam_role_policy" "default" {
  for_each = var.transfer_users

  name       = each.value.user_name
  role       = aws_iam_role.default.id
  policy     = each.value.role_policy != null ? each.value.role_policy : local.default_transfer_user_role_policy
  depends_on = [aws_iam_role.default]
}

resource "aws_transfer_user" "default" {
  for_each = var.transfer_users

  server_id      = aws_transfer_server.default.id
  user_name      = each.value.user_name
  home_directory = each.value.home_directory
  role           = aws_iam_role.default.arn
  depends_on     = [aws_iam_role.default]
}

resource "aws_transfer_ssh_key" "default" {
  count = length(local.user_name_ssh_pub_keys)

  server_id  = aws_transfer_server.default.id
  user_name  = local.user_name_ssh_pub_keys[count.index].user_name
  body       = local.user_name_ssh_pub_keys[count.index].ssh_pub_key
  depends_on = [aws_transfer_user.default]
}

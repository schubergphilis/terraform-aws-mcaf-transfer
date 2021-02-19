locals {
  endpoint_details = var.endpoint_details != null ? { create = true } : {}
  user_policy      = data.aws_iam_policy_document.user_policy.json
  user_ssh_keys = { for item in flatten([
    for user, config in var.users : [
      for index, ssh_key in config.ssh_pub_keys : {
        index   = index
        user    = user
        ssh_key = ssh_key
      }
    ]
  ]) : "${item.user}:${item.index}" => item }
}

data "aws_iam_policy_document" "user_policy" {
  statement {
    actions = [
      "s3:*"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "assume_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "server" {
  name               = "TransferRole-${var.name}"
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "server" {
  role       = aws_iam_role.server.id
  policy_arn = var.logging_policy
}

resource "aws_transfer_server" "default" {
  identity_provider_type = "SERVICE_MANAGED"
  endpoint_type          = upper(var.endpoint_type)
  logging_role           = aws_iam_role.server.arn
  tags                   = var.tags

  dynamic "endpoint_details" {
    for_each = local.endpoint_details

    content {
      address_allocation_ids = var.endpoint_details.address_allocation_ids
      subnet_ids             = var.endpoint_details.subnet_ids
      vpc_id                 = var.endpoint_details.vpc_id
    }
  }
}

resource "aws_iam_role" "user" {
  for_each = var.users

  name               = "TransferUserRole-${var.name}-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "user" {
  for_each = var.users

  name   = "TransferUserPolicy-${var.name}-${each.key}"
  policy = each.value.role_policy != null ? each.value.role_policy : local.user_policy
  role   = aws_iam_role.user[each.key].id
}

resource "aws_transfer_user" "default" {
  for_each = var.users

  user_name      = each.key
  home_directory = each.value.home_directory
  role           = aws_iam_role.user[each.key].arn
  server_id      = aws_transfer_server.default.id
}

resource "aws_transfer_ssh_key" "default" {
  for_each = local.user_ssh_keys

  user_name = aws_transfer_user.default[each.value.user].user_name
  body      = each.value.ssh_key
  server_id = aws_transfer_server.default.id
}

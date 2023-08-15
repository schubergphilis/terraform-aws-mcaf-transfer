locals {
  user_policy          = data.aws_iam_policy_document.user_policy.json
  vpc_endpoint         = var.vpc_endpoint != null ? { create = true } : {}
  on_upload            = var.on_upload != null ? { create = true } : {}
  on_partial_upload    = var.on_partial_upload != null ? { create = true } : {}
  workflow_details     = length(merge(local.on_upload, local.on_partial_upload)) > 0 ? { create = true } : {}

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
  name                 = "TransferRole-${var.name}"
  assume_role_policy   = data.aws_iam_policy_document.assume_policy.json
  permissions_boundary = var.permissions_boundary
  tags                 = var.tags
}

resource "aws_iam_role_policy_attachment" "server" {
  role       = aws_iam_role.server.id
  policy_arn = var.logging_policy
}

resource "aws_transfer_server" "default" {
  endpoint_type                   = var.endpoint_type
  identity_provider_type          = "SERVICE_MANAGED"
  logging_role                    = aws_iam_role.server.arn
  pre_authentication_login_banner = var.pre_login_banner
  security_policy_name            = var.transfer_security_policy
  tags                            = var.tags

  dynamic "endpoint_details" {
    for_each = local.vpc_endpoint

    content {
      # Provide these 4 for endpoint_type = "VPC"
      address_allocation_ids = var.vpc_endpoint.address_allocation_ids
      security_group_ids     = var.vpc_endpoint.security_group_ids
      subnet_ids             = var.vpc_endpoint.subnet_ids
      vpc_id                 = var.vpc_endpoint.vpc_id
      # Provide this 1 for endpoint_type = "VPC_ENDPOINT"
      vpc_endpoint_id = var.vpc_endpoint.vpc_endpoint_id
    }
  }

  dynamic "workflow_details" {
    for_each = local.workflow_details

    content {
      dynamic "on_upload" {
        for_each = local.on_upload

        content {
          execution_role = try(var.on_upload.execution_role, null)
          workflow_id    = try(var.on_upload.workflow_id, null)
        }
      }

      dynamic "on_partial_upload" {
        for_each = local.on_partial_upload

        content {
          execution_role = try(var.on_partial_upload.execution_role, null)
          workflow_id    = try(var.on_partial_upload.workflow_id, null)
        }
      }
    }
  }
}

resource "aws_iam_role" "user" {
  for_each = var.users

  name                 = "TransferUserRole-${var.name}-${each.key}"
  assume_role_policy   = data.aws_iam_policy_document.assume_policy.json
  permissions_boundary = var.permissions_boundary
  tags                 = var.tags
}

resource "aws_iam_role_policy" "user" {
  for_each = var.users

  name   = "TransferUserPolicy-${var.name}-${each.key}"
  policy = each.value.role_policy != null ? each.value.role_policy : local.user_policy
  role   = aws_iam_role.user[each.key].id
}

resource "aws_transfer_user" "default" {
  for_each = var.users

  user_name           = each.key
  home_directory      = var.restricted_mode ? null : each.value.home_directory
  home_directory_type = var.restricted_mode ? "LOGICAL" : "PATH"
  role                = aws_iam_role.user[each.key].arn
  server_id           = aws_transfer_server.default.id
  tags                = var.tags

  dynamic "home_directory_mappings" {
    for_each = var.restricted_mode ? [1] : []
    content {
      entry  = "/"
      target = each.value.home_directory
    }
  }
}

resource "aws_transfer_ssh_key" "default" {
  for_each = local.user_ssh_keys

  user_name = aws_transfer_user.default[each.value.user].user_name
  body      = each.value.ssh_key
  server_id = aws_transfer_server.default.id
}

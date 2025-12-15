locals {
  vpc_endpoint      = var.vpc_endpoint != null ? { create = true } : {}
  on_upload         = var.on_upload != null ? { create = true } : {}
  on_partial_upload = var.on_partial_upload != null ? { create = true } : {}
  workflow_details  = length(merge(local.on_upload, local.on_partial_upload)) > 0 ? { create = true } : {}

  # Flatten users' SSH keys into a stable map
  user_ssh_keys = {
    for item in flatten([
      for user, config in var.users : [
        for idx, ssh_key in config.ssh_pub_keys : {
          index   = idx
          user    = user
          ssh_key = ssh_key
        }
      ]
    ]) : "${item.user}:${item.index}" => item
  }
}

resource "aws_transfer_server" "default" {
  #checkov:skip=CKV_AWS_164: PUBLIC endpoint is required for our SFTP use case
  lifecycle {
    # keep host key safe
    # prevent_destroy = true

    # PUBLIC → vpc_endpoint must be null
    precondition {
      condition     = (var.endpoint_type != "PUBLIC") || (var.vpc_endpoint == null)
      error_message = "endpoint_type=PUBLIC requires vpc_endpoint to be null."
    }

    # VPC → require SGs, subnets, and vpc_id
    precondition {
      condition = (
        var.endpoint_type != "VPC" ||
        (
          var.vpc_endpoint != null &&
          length(coalesce(try(var.vpc_endpoint.security_group_ids, []), [])) > 0 &&
          length(coalesce(try(var.vpc_endpoint.subnet_ids, []), [])) > 0 &&
          try(var.vpc_endpoint.vpc_id, "") != ""
        )
      )
      error_message = "endpoint_type=VPC requires vpc_endpoint.security_group_ids, vpc_endpoint.subnet_ids, and vpc_endpoint.vpc_id."
    }

    # VPC_ENDPOINT → require only vpc_endpoint_id (no SGs/subnets/vpc_id)
    precondition {
      condition = (
        var.endpoint_type != "VPC_ENDPOINT" ||
        (
          var.vpc_endpoint != null &&
          try(var.vpc_endpoint.vpc_endpoint_id, "") != "" &&
          length(coalesce(try(var.vpc_endpoint.security_group_ids, []), [])) == 0 &&
          length(coalesce(try(var.vpc_endpoint.subnet_ids, []), [])) == 0 &&
          try(var.vpc_endpoint.vpc_id, null) == null
        )
      )
      error_message = "endpoint_type=VPC_ENDPOINT requires vpc_endpoint.vpc_endpoint_id and forbids security_group_ids, subnet_ids, and vpc_id."
    }

    # sftp_authentication_methods is only valid with API_GATEWAY or AWS_LAMBDA
    precondition {
      condition = (
        var.sftp_authentication_methods == null ||
        var.identity_provider_type == "AWS_LAMBDA" ||
        var.identity_provider_type == "API_GATEWAY"
      )
      error_message = "sftp_authentication_methods is only supported for identity_provider_type of API_GATEWAY or AWS_LAMBDA."
    }

    # Security: explicitly forbid FTP even if validation is bypassed
    precondition {
      condition     = !contains(var.protocols, "FTP")
      error_message = "FTP is not allowed by this module."
    }

    # Security: forbid PASSWORD-only SFTP auth
    precondition {
      condition     = (var.sftp_authentication_methods == null) || (var.sftp_authentication_methods != "PASSWORD")
      error_message = "sftp_authentication_methods=PASSWORD is not allowed. Use PUBLIC_KEY or PUBLIC_KEY_OR_PASSWORD."
    }

    # Hardening (recommended): if FTPS is enabled on PUBLIC endpoint, require passive_ip to be set
    # to avoid ephemeral public address exposure via control connections/NAT.
    precondition {
      condition = (
        !contains(var.protocols, "FTPS") ||
        var.endpoint_type != "PUBLIC" ||
        (
          var.protocol_details != null &&
          try(var.protocol_details.passive_ip, "") != ""
        )
      )
      error_message = "When protocols include FTPS and endpoint_type=PUBLIC, protocol_details.passive_ip must be set."
    }
  }

  # ── Identity provider & authentication (v5/v6) ──────────────────────────────
  identity_provider_type = var.identity_provider_type
  # NOTE: In v5+, this is a top-level arg (also valid in v6). Only for API_GATEWAY/AWS_LAMBDA.
  sftp_authentication_methods = var.sftp_authentication_methods

  # Top-level IdP detail args (supported in v5 and v6)
  function        = try(var.identity_provider_details.function_arn, null)    # AWS_LAMBDA
  invocation_role = try(var.identity_provider_details.invocation_role, null) # API_GATEWAY
  url             = try(var.identity_provider_details.url, null)             # API_GATEWAY
  directory_id    = try(var.identity_provider_details.directory_id, null)    # AWS_DIRECTORY_SERVICE

  # ── Endpoint & logging ──────────────────────────────────────────────────────
  endpoint_type = var.endpoint_type
  logging_role  = var.logging_role_arn

  # ── Banners & security policy ───────────────────────────────────────────────
  pre_authentication_login_banner  = var.pre_authentication_login_banner
  post_authentication_login_banner = var.post_authentication_login_banner
  security_policy_name             = var.transfer_security_policy

  # ── Protocols ───────────────────────────────────────────────────────────────
  protocols = var.protocols

  # ── Tags (preserve original Name usage) ─────────────────────────────────────
  tags = merge(var.tags, { Name = var.name })

  # ── Endpoint details (VPC / VPC_ENDPOINT) ───────────────────────────────────
  dynamic "endpoint_details" {
    for_each = local.vpc_endpoint
    content {
      address_allocation_ids = try(var.vpc_endpoint.address_allocation_ids, null) # VPC
      security_group_ids     = try(var.vpc_endpoint.security_group_ids, null)     # VPC
      subnet_ids             = try(var.vpc_endpoint.subnet_ids, null)             # VPC
      vpc_id                 = try(var.vpc_endpoint.vpc_id, null)                 # VPC
      vpc_endpoint_id        = try(var.vpc_endpoint.vpc_endpoint_id, null)        # VPC_ENDPOINT
    }
  }

  # ── Workflows ────────────────────────────────────────────────────────────────
  dynamic "workflow_details" {
    for_each = local.workflow_details
    content {
      dynamic "on_upload" {
        for_each = local.on_upload
        content {
          execution_role = var.on_upload.execution_role_arn
          workflow_id    = var.on_upload.workflow_id
        }
      }
      dynamic "on_partial_upload" {
        for_each = local.on_partial_upload
        content {
          execution_role = var.on_partial_upload.execution_role_arn
          workflow_id    = var.on_partial_upload.workflow_id
        }
      }
    }
  }

  # ── Protocol details (FTPS/FTP/AS2 options; v5 and v6) ──────────────────────
  dynamic "protocol_details" {
    for_each = var.protocol_details == null ? {} : { create = true }
    content {
      as2_transports              = try(var.protocol_details.as2_transports, null)
      passive_ip                  = try(var.protocol_details.passive_ip, null)
      tls_session_resumption_mode = try(var.protocol_details.tls_session_resumption_mode, null)
      set_stat_option             = try(var.protocol_details.set_stat_option, null)
      # v6 note: sftp_authentication_methods remains TOP-LEVEL (not here).
    }
  }
}

# ── Optional: explicit server host keys (commented for TF 1.6 bootstrap) ──────
# resource "aws_transfer_host_key" "managed" {
#   count = var.manage_host_keys ? length(var.host_keys) : 0
#   server_id     = aws_transfer_server.default.id
#   host_key_body = var.host_keys[count.index].private_key
#   description   = try(var.host_keys[count.index].description, null)
#   tags = merge(var.tags, { Name = format("%s-host-key-%d", var.name, count.index) })
# }

# Normalize to raw hosted zone ID (strip optional "/hostedzone/" prefix).
locals {
  _route53_zone_id = var.route53_hosted_zone_id == null ? null : regexreplace(var.route53_hosted_zone_id, "^/hostedzone/", "")
}

resource "aws_transfer_tag" "custom_hostname" {
  count        = var.custom_hostname == null ? 0 : 1
  resource_arn = aws_transfer_server.default.arn
  key          = "transfer:customHostname"
  value        = var.custom_hostname
}

resource "aws_transfer_tag" "route53_zone" {
  count        = local._route53_zone_id == null ? 0 : 1
  resource_arn = aws_transfer_server.default.arn
  key          = "transfer:route53HostedZoneId"
  value        = local._route53_zone_id
}

# ── Users (IAM roles provided by caller) ───────────────────────────────────────
resource "aws_transfer_user" "default" {
  for_each = var.users

  user_name           = each.key
  role                = each.value.role_arn
  server_id           = aws_transfer_server.default.id
  home_directory      = var.restricted_mode ? null : each.value.home_directory
  home_directory_type = var.restricted_mode ? "LOGICAL" : "PATH"

  # Preserve Name tagging pattern with var.name
  tags = merge(var.tags, { Name = "${var.name}-${each.key}" })

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

  server_id = aws_transfer_server.default.id
  user_name = aws_transfer_user.default[each.value.user].user_name
  body      = each.value.ssh_key
}

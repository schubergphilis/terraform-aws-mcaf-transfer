# Mock aws provider, otherwise Terraform tries to connect to the service API.
mock_provider "aws" {
  # Mock data.aws_region: we always want to return "eu-central-1" for our tests.
  mock_data "aws_region" {
    defaults = {
      region = "eu-central-1"
    }
  }
}

run "setup" {
  module {
    source = "./tests/setup"
  }
}

# -----------------------------------------------------------------------------
# Default: PUBLIC endpoint, SFTP only, SERVICE_MANAGED IdP, hardened policy
# -----------------------------------------------------------------------------
run "default" {
  command = plan

  module {
    source = "./"
  }

  variables {
    name                     = "example"
    tags                     = { env = "test" }
    logging_role_arn         = "arn:aws:iam::123456789012:role/transfer-logging"
    transfer_security_policy = "TransferSecurityPolicy-2025-03"
    # protocols default to ["SFTP"]
  }

  assert {
    condition     = aws_transfer_server.default.endpoint_type == "PUBLIC"
    error_message = "Expected endpoint_type to be PUBLIC, got: ${aws_transfer_server.default.endpoint_type}"
  }

  assert {
    condition     = jsonencode(aws_transfer_server.default.protocols) == jsonencode(["SFTP"])
    error_message = "Expected default protocols to be [\"SFTP\"], got: ${jsonencode(aws_transfer_server.default.protocols)}"
  }

  assert {
    condition     = aws_transfer_server.default.identity_provider_type == "SERVICE_MANAGED"
    error_message = "Expected identity_provider_type to be SERVICE_MANAGED, got: ${aws_transfer_server.default.identity_provider_type}"
  }

  assert {
    condition     = aws_transfer_server.default.security_policy_name == "TransferSecurityPolicy-2025-03"
    error_message = "Expected security_policy_name to be TransferSecurityPolicy-2025-03, got: ${aws_transfer_server.default.security_policy_name}"
  }

  # Tag merge preserves Name=<name>
  assert {
    condition     = aws_transfer_server.default.tags.Name == "example"
    error_message = "Expected Name tag to equal module name 'example', got: ${aws_transfer_server.default.tags.Name}"
  }
}

# -----------------------------------------------------------------------------
# VPC endpoint type: requires vpc_id, subnet_ids, security_group_ids
# -----------------------------------------------------------------------------
run "vpc_endpoint_type" {
  command = plan

  module {
    source = "./"
  }

  variables {
    name                     = "example-vpc"
    logging_role_arn         = "arn:aws:iam::123456789012:role/transfer-logging"
    transfer_security_policy = "TransferSecurityPolicy-2025-03"

    endpoint_type = "VPC"
    vpc_endpoint = {
      vpc_id                 = "vpc-0123456789abcdef0"
      subnet_ids             = ["subnet-11111111", "subnet-22222222"]
      security_group_ids     = ["sg-0123456789abcdef0"]
      address_allocation_ids = ["eipalloc-aaaabbbb", "eipalloc-ccccdddd"] # optional
    }
  }

  assert {
    condition     = aws_transfer_server.default.endpoint_type == "VPC"
    error_message = "Expected endpoint_type VPC, got: ${aws_transfer_server.default.endpoint_type}"
  }

  # Endpoint details present
  assert {
    condition     = aws_transfer_server.default.endpoint_details[0].vpc_id == "vpc-0123456789abcdef0"
    error_message = "Expected endpoint_details.vpc_id to be vpc-0123456789abcdef0, got: ${aws_transfer_server.default.endpoint_details[0].vpc_id}"
  }

  assert {
    condition     = length(aws_transfer_server.default.endpoint_details[0].subnet_ids) == 2
    error_message = "Expected two subnet_ids, got: ${length(aws_transfer_server.default.endpoint_details[0].subnet_ids)}"
  }

  assert {
    condition     = length(aws_transfer_server.default.endpoint_details[0].security_group_ids) == 1
    error_message = "Expected one security_group_id, got: ${length(aws_transfer_server.default.endpoint_details[0].security_group_ids)}"
  }

  assert {
    condition     = length(aws_transfer_server.default.endpoint_details[0].address_allocation_ids) == 2
    error_message = "Expected two EIP allocations, got: ${length(aws_transfer_server.default.endpoint_details[0].address_allocation_ids)}"
  }
}

# -----------------------------------------------------------------------------
# VPC_ENDPOINT endpoint type: must provide only vpc_endpoint_id
# -----------------------------------------------------------------------------
run "vpc_interface_endpoint_type" {
  command = plan

  module {
    source = "./"
  }

  variables {
    name                     = "example-vpce"
    logging_role_arn         = "arn:aws:iam::123456789012:role/transfer-logging"
    transfer_security_policy = "TransferSecurityPolicy-2025-03"

    endpoint_type = "VPC_ENDPOINT"
    vpc_endpoint = {
      vpc_endpoint_id = "vpce-0abc0123456789def"
    }
  }

  assert {
    condition     = aws_transfer_server.default.endpoint_type == "VPC_ENDPOINT"
    error_message = "Expected endpoint_type VPC_ENDPOINT, got: ${aws_transfer_server.default.endpoint_type}"
  }

  assert {
    condition     = aws_transfer_server.default.endpoint_details[0].vpc_endpoint_id == "vpce-0abc0123456789def"
    error_message = "Expected vpc_endpoint_id to match, got: ${aws_transfer_server.default.endpoint_details[0].vpc_endpoint_id}"
  }

  # NOTE: Do not assert emptiness of security_group_ids/subnet_ids/vpc_id here:
  # under provider v5 these can be unknown at plan time and cause test failures.
}


# -----------------------------------------------------------------------------
# AWS_LAMBDA IdP with SFTP auth methods (explicit so it's known at plan time)
# -----------------------------------------------------------------------------
run "lambda_idp" {
  command = plan

  module {
    source = "./"
  }

  variables {
    name                     = "example-lambda-idp"
    logging_role_arn         = "arn:aws:iam::123456789012:role/transfer-logging"
    transfer_security_policy = "TransferSecurityPolicy-2025-03"

    identity_provider_type      = "AWS_LAMBDA"
    sftp_authentication_methods = "PUBLIC_KEY_OR_PASSWORD"

    identity_provider_details = {
      function_arn = "arn:aws:lambda:eu-central-1:123456789012:function:transfer-idp"
    }
  }

  assert {
    condition     = aws_transfer_server.default.identity_provider_type == "AWS_LAMBDA"
    error_message = "Expected identity_provider_type AWS_LAMBDA, got: ${aws_transfer_server.default.identity_provider_type}"
  }

  assert {
    condition     = aws_transfer_server.default.function == "arn:aws:lambda:eu-central-1:123456789012:function:transfer-idp"
    error_message = "Expected Lambda function ARN to match, got: ${aws_transfer_server.default.function}"
  }

  assert {
    condition     = aws_transfer_server.default.sftp_authentication_methods == "PUBLIC_KEY_OR_PASSWORD"
    error_message = "Expected sftp_authentication_methods PUBLIC_KEY_OR_PASSWORD, got: ${aws_transfer_server.default.sftp_authentication_methods}"
  }
}

# -----------------------------------------------------------------------------
# API_GATEWAY IdP with SFTP auth methods (explicit so it's known at plan time)
# -----------------------------------------------------------------------------
run "apigw_idp" {
  command = plan

  module {
    source = "./"
  }

  variables {
    name                     = "example-apigw-idp"
    logging_role_arn         = "arn:aws:iam::123456789012:role/transfer-logging"
    transfer_security_policy = "TransferSecurityPolicy-2025-03"

    identity_provider_type      = "API_GATEWAY"
    sftp_authentication_methods = "PUBLIC_KEY"

    identity_provider_details = {
      url             = "https://abc123.execute-api.eu-central-1.amazonaws.com/prod/auth"
      invocation_role = "arn:aws:iam::123456789012:role/transfer-apigw-invoke"
    }
  }

  assert {
    condition     = aws_transfer_server.default.identity_provider_type == "API_GATEWAY"
    error_message = "Expected identity_provider_type API_GATEWAY, got: ${aws_transfer_server.default.identity_provider_type}"
  }

  assert {
    condition     = aws_transfer_server.default.url == "https://abc123.execute-api.eu-central-1.amazonaws.com/prod/auth"
    error_message = "Expected API Gateway URL to match, got: ${aws_transfer_server.default.url}"
  }

  assert {
    condition     = aws_transfer_server.default.invocation_role == "arn:aws:iam::123456789012:role/transfer-apigw-invoke"
    error_message = "Expected invocation_role to match, got: ${aws_transfer_server.default.invocation_role}"
  }

  assert {
    condition     = aws_transfer_server.default.sftp_authentication_methods == "PUBLIC_KEY"
    error_message = "Expected sftp_authentication_methods PUBLIC_KEY, got: ${aws_transfer_server.default.sftp_authentication_methods}"
  }
}

# -----------------------------------------------------------------------------
# FTPS protocol_details (PUBLIC endpoint requires passive_ip by module precondition)
# -----------------------------------------------------------------------------
run "ftps_details" {
  command = plan

  module {
    source = "./"
  }

  variables {
    name                     = "example-ftps"
    logging_role_arn         = "arn:aws:iam::123456789012:role/transfer-logging"
    transfer_security_policy = "TransferSecurityPolicy-2025-03"

    endpoint_type = "PUBLIC"
    protocols     = ["FTPS"]

    protocol_details = {
      passive_ip                  = "198.51.100.42"
      tls_session_resumption_mode = "ENABLED"
    }
  }

  assert {
    condition     = jsonencode(aws_transfer_server.default.protocols) == jsonencode(["FTPS"])
    error_message = "Expected FTPS protocol enabled, got: ${jsonencode(aws_transfer_server.default.protocols)}"
  }

  assert {
    condition     = aws_transfer_server.default.protocol_details[0].passive_ip == "198.51.100.42"
    error_message = "Expected passive_ip to be set, got: ${aws_transfer_server.default.protocol_details[0].passive_ip}"
  }

  assert {
    condition     = aws_transfer_server.default.protocol_details[0].tls_session_resumption_mode == "ENABLED"
    error_message = "Expected tls_session_resumption_mode to be ENABLED, got: ${aws_transfer_server.default.protocol_details[0].tls_session_resumption_mode}"
  }
}

# -----------------------------------------------------------------------------
# AS2 protocol_details
# -----------------------------------------------------------------------------
run "as2_details" {
  command = plan

  module {
    source = "./"
  }

  variables {
    name                     = "example-as2"
    logging_role_arn         = "arn:aws:iam::123456789012:role/transfer-logging"
    transfer_security_policy = "TransferSecurityPolicy-2025-03"

    protocols = ["AS2"]

    protocol_details = {
      as2_transports = ["HTTP"]
    }
  }

  assert {
    condition     = jsonencode(aws_transfer_server.default.protocols) == jsonencode(["AS2"])
    error_message = "Expected AS2 protocol enabled, got: ${jsonencode(aws_transfer_server.default.protocols)}"
  }

  # as2_transports is a set, so check membership instead of indexing
  assert {
    condition     = contains(aws_transfer_server.default.protocol_details[0].as2_transports, "HTTP")
    error_message = "Expected as2_transports to include HTTP, got: ${jsonencode(aws_transfer_server.default.protocol_details[0].as2_transports)}"
  }
}

# -----------------------------------------------------------------------------
# Mixed protocols SFTP + FTPS with protocol_details for FTPS
# -----------------------------------------------------------------------------
run "sftp_ftps_mixed" {
  command = plan

  module {
    source = "./"
  }

  variables {
    name                     = "example-sftp-ftps"
    logging_role_arn         = "arn:aws:iam::123456789012:role/transfer-logging"
    transfer_security_policy = "TransferSecurityPolicy-2025-03"

    protocols = ["SFTP", "FTPS"]

    protocol_details = {
      passive_ip                  = "198.51.100.88"
      tls_session_resumption_mode = "ENABLED"
    }

    identity_provider_type      = "SERVICE_MANAGED"
    sftp_authentication_methods = null
  }

  assert {
    condition     = toset(aws_transfer_server.default.protocols) == toset(["SFTP", "FTPS"])
    error_message = "Expected protocols to include SFTP and FTPS (order-agnostic), got: ${jsonencode(aws_transfer_server.default.protocols)}"
  }

  assert {
    condition     = aws_transfer_server.default.protocol_details[0].passive_ip == "198.51.100.88"
    error_message = "Expected FTPS passive_ip to match, got: ${aws_transfer_server.default.protocol_details[0].passive_ip}"
  }

  assert {
    condition     = aws_transfer_server.default.identity_provider_type == "SERVICE_MANAGED"
    error_message = "Expected SERVICE_MANAGED identity provider, got: ${aws_transfer_server.default.identity_provider_type}"
  }
}

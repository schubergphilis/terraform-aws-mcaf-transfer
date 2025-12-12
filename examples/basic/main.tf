##############################################
# Minimal example (no boundary policy)
# - PUBLIC Transfer server
# - One example user with SSH key
##############################################

provider "aws" {
  region = "eu-west-1"
}

# Trust policy for AWS Transfer service
data "aws_iam_policy_document" "assume_transfer" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
  }
}

##############################################
# Logging role (no boundary)
##############################################

resource "aws_iam_role" "transfer_logging" {
  name               = "example-transfer-logging"
  assume_role_policy = data.aws_iam_policy_document.assume_transfer.json
  tags               = { Project = "example" }
}

resource "aws_iam_role_policy_attachment" "transfer_logging_access" {
  role       = aws_iam_role.transfer_logging.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
}

##############################################
# Example user role (no boundary)
##############################################

# Minimal user policy: list bucket + read objects
data "aws_iam_policy_document" "example_user" {
  statement {
    actions = ["s3:ListBucket"]
    resources = [
      "arn:aws:s3:::example-bucket"
    ]
  }
  statement {
    actions = ["s3:GetObject"]
    resources = [
      "arn:aws:s3:::example-bucket/*"
    ]
  }
}

resource "aws_iam_role" "transfer_user" {
  name               = "example-transfer-user"
  assume_role_policy = data.aws_iam_policy_document.assume_transfer.json
  tags               = { Project = "example" }
}

resource "aws_iam_role_policy" "transfer_user_inline" {
  name   = "example-transfer-user-policy"
  role   = aws_iam_role.transfer_user.name
  policy = data.aws_iam_policy_document.example_user.json
}

##############################################
# Users map for the module
##############################################

locals {
  users = {
    "alice" = {
      home_directory = "/example-bucket/alice"
      role_arn       = aws_iam_role.transfer_user.arn
      ssh_pub_keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE... alice@example"
      ]
    }
  }
}

##############################################
# Module call (PUBLIC server)
##############################################

module "transfer_server" {
  source = "../.."

  name = "example-transfer"
  tags = { Project = "example" }

  endpoint_type    = "PUBLIC"
  logging_role_arn = aws_iam_role.transfer_logging.arn
  users            = local.users

  restricted_mode          = false
  transfer_security_policy = "TransferSecurityPolicy-2024-01"

  pre_authentication_login_banner = <<EOF
Unauthorized access prohibited.
EOF
}

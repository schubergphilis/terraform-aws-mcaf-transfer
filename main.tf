# Provides a role to be both used as transfer user role and transfer server role
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

resource "aws_iam_role_policy" "default" {
  name       = var.name
  role       = aws_iam_role.default.id
  policy     = var.role_policy
  depends_on = [aws_iam_role.default]

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
  endpoint_type          = var.endpoint_type

  endpoint_details {
    vpc_endpoint_id = var.vpc_endpoint_id
  }
  depends_on = [aws_iam_role.default]
}

resource "aws_transfer_user" "default" {
  server_id      = aws_transfer_server.default.id
  user_name      = var.name
  role           = aws_iam_role.default.arn
  home_directory = var.home_directory
  depends_on     = [aws_iam_role.default]
}

resource "aws_transfer_ssh_key" "default" {
  count      = length(var.ssh_pub_keys)
  server_id  = aws_transfer_server.default.id
  user_name  = aws_transfer_user.default.user_name
  body       = var.ssh_pub_keys[count.index]
  depends_on = [aws_transfer_user.default]
}

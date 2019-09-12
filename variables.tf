variable "name" {
  type        = string
  description = "The transfer username, IAM role and role policy name"
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resources"
}

variable "ssh_pub_keys" {
  type        = list(string)
  description = "List of public SSH keys to connect to the AWS tranfer service"
  default     = []
}

variable "home_directory" {
  type        = string
  description = "Home directory in the format '/<bucket-name>/directory'"
  default     = ""
}

variable "role_policy" {
  type        = string
  description = "Default role policy for the transfer user"
  default     = <<POLICY
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

variable "logging_policy" {
  type        = string
  description = "Default logging policy for the transfer server"
  default     = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
}

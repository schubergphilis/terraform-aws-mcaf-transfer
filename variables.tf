variable "name" {
  type        = string
  description = "The transfer username, IAM role and role policy name"
}

variable "endpoint_type" {
  type        = string
  description = "The endpoint type, can be VPC_ENDPOINT or PUBLIC"
  default     = "PUBLIC"
}

variable "vpc_endpoint_id" {
  type        = string
  description = "The endpoint ID"
  default     = null
}

variable "logging_policy" {
  type        = string
  description = "Default logging policy for the transfer server"
  default     = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
}

/* user_name: Username of the transfer user
   home_directory: Home directory in the format '/<bucket-name>/directory'
   role_policy: Role policy for the transfer user (optional, null value is allowed)
   ssh_pub_keys: List of public SSH keys to connect to the AWS tranfer service */
variable "transfer_users" {
  type = map(object({
    user_name      = string
    home_directory = string
    role_policy    = string
    ssh_pub_keys   = list(string)
  }))
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resources"
}

variable "logging_policy" {
  type        = string
  default     = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
  description = "Default logging policy for the transfer server"
}

variable "name" {
  type        = string
  description = "A unique name for this transfer server instance"
}

variable "permissions_boundary" {
  type        = string
  default     = null
  description = "The permissions boundary to set on the role"
}

variable "restricted_mode" {
  type        = bool
  default     = false
  description = "Optional restricted mode. Requires s3_id."
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resources"
}

variable "transfer_security_policy" {
  type    = string
  default = null
}

variable "s3_id" {
  type        = string
  default     = ""
  description = "Optional name of the bucket used by AWS Transfer service. Required when using restricted_mode."
}

variable "users" {
  type = map(object({
    home_directory = string
    role_policy    = string
    ssh_pub_keys   = list(string)
  }))
  description = "A map with transfer users and configuration details"
}

variable "vpc_endpoint" {
  type = object({
    address_allocation_ids = list(string)
    subnet_ids             = list(string)
    vpc_id                 = string
  })
  default     = null
  description = "Optional VPC endpoint settings for your SFTP server"
}

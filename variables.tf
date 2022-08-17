variable "logging_policy" {
  type        = string
  default     = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
  description = "Default logging policy for the transfer server"
}

variable "name" {
  type        = string
  description = "A unique name for this transfer server instance"
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resources"
}

variable "users" {
  type = map(object({
    home_directory = string
    role_policy    = string
    ssh_pub_keys   = list(string)
  }))
  description = "A map with transfer users and configuration details"
}

variable "s3_id" {
  type    = string
  default = ""
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
variable "restricted_mode" {
  type    = bool
  default = false
}

variable "permissions_boundary" {
  type        = string
  default     = null
  description = "The permissions boundary to set on the role"
}

variable "login_banner" {
  type    = string
  default = null
}

variable "transfer_security_policy" {
  type    = string
  default = null
}

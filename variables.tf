variable "logging_policy" {
  type        = string
  default     = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
  description = "Default logging policy for the transfer server"
}

variable "name" {
  type        = string
  description = "A unique name for this transfer server instance"
}

variable "on_upload" {
  type = object({
    execution_role = string
    workflow_id    = string
  })
  default     = null
  description = "Optional trigger to execute a workflow after a file is uploaded"
}

variable "on_partial_upload" {
  type = object({
    execution_role = string
    workflow_id    = string
  })
  default     = null
  description = "Optional trigger to execute a workflow after a file is partially uploaded"
}

variable "permissions_boundary" {
  type        = string
  default     = null
  description = "The permissions boundary to set on the role"
}

variable "pre_login_banner" {
  type        = string
  default     = null
  description = "Login banner presented before logging on to the AWS Transfer server"
}

variable "restricted_mode" {
  type        = bool
  default     = false
  description = "Lock down all users to their home directory."
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resources"
}

variable "transfer_security_policy" {
  type        = string
  default     = null
  description = "Define the set of cryptographic algorithms accepted by the service."
}

variable "users" {
  type = map(object({
    home_directory = string
    role_policy    = string
    ssh_pub_keys   = list(string)
  }))
  description = "A map with transfer users and configuration details"
}

variable "endpoint_type" {
  description = "Type of endpoint"
  type        = string
  default     = "PUBLIC"
  validation {
    condition     = contains(["PUBLIC", "VPC", "VPC_ENDPOINT"], var.endpoint_type)
    error_message = "Allowed values for endpoint_type are PUBLIC, VPC, or VPC_ENDPOINT"
  }
}

variable "vpc_endpoint" {
  type = object({
    address_allocation_ids = optional(list(string))
    security_group_ids     = optional(list(string))
    subnet_ids             = optional(list(string))
    vpc_endpoint_id        = optional(string)
    vpc_id                 = optional(string)
  })
  default     = null
  description = "Optional VPC endpoint settings for your SFTP server"
}

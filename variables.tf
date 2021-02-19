variable "endpoint_details" {
  type = object({
    address_allocation_ids = list(string)
    subnet_ids             = list(string)
    vpc_id                 = string
  })
  default     = null
  description = "VPC endpoint configuration, required when using endpoint type VPC (address_allocation_ids is optional)"
}

variable "endpoint_type" {
  type        = string
  default     = "PUBLIC"
  description = "The endpoint type, can be VPC or PUBLIC"
}

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

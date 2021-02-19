variable "endpoint_details" {
  type = object({
    vpc_id                 = string
    subnet_ids             = list(string)
    address_allocation_ids = list(string)
  })
  default     = null
  description = "Variables needed when using endpoint_type VPC: VPC ID, Subnet ID, Public Elastic IP)"
}

variable "endpoint_type" {
  type        = string
  default     = "PUBLIC"
  description = "The endpoint type, can be VPC_ENDPOINT or PUBLIC"
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

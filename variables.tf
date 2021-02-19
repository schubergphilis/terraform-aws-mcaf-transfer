variable "address_allocation_ids" {
  type        = list(string)
  default     = null
  description = "Optional Public Elastic IPs"
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

variable "subnet_ids" {
  type        = list(string)
  default     = null
  description = "Optional Subnet IDs"
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

variable "vpc_id" {
  type        = string
  default     = null
  description = "An optional VPC ID"
}

variable "name" {
  type        = string
  description = "The user, role and default policy name"
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resources"
}

variable "ssh_pub_key" {
  type        = string
  description = "Public SSH key to connect to the AWS tranfer service"
}

variable "home_directory" {
  type        = string
  description = "Home directory in the format '/<bucket-name>/directory'"
}

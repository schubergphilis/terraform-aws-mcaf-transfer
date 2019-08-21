variable "name" {
  type        = string
  description = "The user, role and policy name"
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resources"
}

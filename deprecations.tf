################################################################################
# Deprecations – legacy variables retained for warnings only
# These variables are no-ops in the modernized module and will be removed
# in a future major version. They exist solely to provide clear plan-time
# messaging during migrations.
################################################################################

# tflint-ignore: terraform_unused_declarations
variable "permissions_boundary" {
  type        = string
  default     = null
  description = "DEPRECATED: Previously applied to IAM roles created by this module. Roles are now external."
}

output "permissions_boundary_deprecation" {
  value       = { message = var.permissions_boundary != null ? "⚠️ Warning: 'permissions_boundary' is deprecated and ignored. IAM roles are created outside this module and should apply boundaries there." : "✅ No deprecation warning for 'permissions_boundary'." }
  description = "Deprecation message for permissions_boundary."
}

# tflint-ignore: terraform_unused_declarations
variable "logging_policy" {
  type        = string
  default     = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
  description = "DEPRECATED: Previously attached to an internal logging role. Provide an external logging_role_arn instead."
}

output "logging_policy_deprecation" {
  value       = { message = var.logging_policy != "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess" ? "⚠️ Warning: 'logging_policy' is deprecated and ignored. Use an external 'logging_role_arn' with the required permissions." : "✅ No deprecation warning for 'logging_policy'." }
  description = "Deprecation message for logging_policy."
}

# tflint-ignore: terraform_unused_declarations
variable "pre_login_banner" {
  type        = string
  default     = null
  description = "DEPRECATED: Replaced by 'pre_authentication_login_banner'."
}

output "pre_login_banner_deprecation" {
  value       = { message = var.pre_login_banner != null ? "⚠️ Warning: 'pre_login_banner' is deprecated and ignored. Use 'pre_authentication_login_banner' instead." : "✅ No deprecation warning for 'pre_login_banner'." }
  description = "Deprecation message for pre_login_banner."
}

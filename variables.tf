# ──────────────────────────────────────────────────────────────────────────────
# Core identifiers
# ──────────────────────────────────────────────────────────────────────────────
variable "name" {
  type        = string
  description = "A unique name for this transfer server instance."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to assign to resources. Prefer provider default_tags at root."
}

# ──────────────────────────────────────────────────────────────────────────────
# Endpoint configuration
# ──────────────────────────────────────────────────────────────────────────────
variable "endpoint_type" {
  description = "Endpoint type: PUBLIC | VPC | VPC_ENDPOINT"
  type        = string
  default     = "PUBLIC"
  validation {
    condition     = contains(["PUBLIC", "VPC", "VPC_ENDPOINT"], var.endpoint_type)
    error_message = "Allowed values: PUBLIC, VPC, or VPC_ENDPOINT."
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
  description = "Endpoint details depending on endpoint_type. For VPC, set vpc_id, subnet_ids, security_group_ids[, address_allocation_ids]. For VPC_ENDPOINT, set vpc_endpoint_id."
}

# ──────────────────────────────────────────────────────────────────────────────
# Protocols & security policy
# ──────────────────────────────────────────────────────────────────────────────
variable "protocols" {
  description = "Enabled protocols: any of SFTP, FTPS, FTP, AS2."
  type        = list(string)
  default     = ["SFTP"]
  validation {
    condition     = alltrue([for p in var.protocols : contains(["SFTP", "FTPS", "FTP", "AS2"], p)]) && length(var.protocols) > 0
    error_message = "Protocols must be a non-empty list with elements in {SFTP, FTPS, FTP, AS2}."
  }
}

variable "transfer_security_policy" {
  type = string
  # Choose a provider-supported policy your org approves.
  # Examples: TransferSecurityPolicy-2025-03, TransferSecurityPolicy-2024-01,
  # TransferSecurityPolicy-FIPS-2025-03, TransferSecurityPolicy-Restricted-2024-06
  default     = "TransferSecurityPolicy-2025-03"
  description = "Explicit AWS Transfer security policy name. Pin a current, provider-supported value to avoid drift and satisfy CKV_AWS_380."

  # Basic format check: require the canonical prefix and a YYYY-MM suffix segment.
  # (Allows FIPS/Restricted/PQ variants too.)
  validation {
    condition     = can(regex("^TransferSecurityPolicy(-[A-Za-z]+)?-\\d{4}-\\d{2}$", var.transfer_security_policy))
    error_message = "transfer_security_policy must look like TransferSecurityPolicy-YYYY-MM (optionally with a variant, e.g., -FIPS-YYYY-MM)."
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Identity provider
# ──────────────────────────────────────────────────────────────────────────────
variable "identity_provider_type" {
  type        = string
  default     = "SERVICE_MANAGED"
  description = "SERVICE_MANAGED | AWS_LAMBDA | API_GATEWAY | AWS_DIRECTORY_SERVICE"
  validation {
    condition     = contains(["SERVICE_MANAGED", "AWS_LAMBDA", "API_GATEWAY", "AWS_DIRECTORY_SERVICE"], var.identity_provider_type)
    error_message = "identity_provider_type must be one of SERVICE_MANAGED, AWS_LAMBDA, API_GATEWAY, AWS_DIRECTORY_SERVICE."
  }
}

variable "identity_provider_details" {
  type = object({
    function_arn    = optional(string) # For AWS_LAMBDA
    invocation_role = optional(string) # For API_GATEWAY
    url             = optional(string) # For API_GATEWAY
    directory_id    = optional(string) # For AWS_DIRECTORY_SERVICE
  })
  default     = null
  description = "Optional identity provider details; fields depend on identity_provider_type."
}

# ──────────────────────────────────────────────────────────────────────────────
# Protocol details
# ──────────────────────────────────────────────────────────────────────────────
variable "protocol_details" {
  type = object({
    as2_transports              = optional(list(string)) # e.g., ["HTTP"] for AS2
    passive_ip                  = optional(string)       # FTPS/FTP passive-mode public IP
    tls_session_resumption_mode = optional(string)       # ENABLED | DISABLED
    set_stat_option             = optional(string)       # ENABLE_NO_OP | DISABLED
  })
  default     = null
  description = "Advanced protocol details; validated against protocol and identity settings."
}

# ──────────────────────────────────────────────────────────────────────────────
# SFTP authentication (top-level; not part of protocol_details)
# ──────────────────────────────────────────────────────────────────────────────
variable "sftp_authentication_methods" {
  type        = string
  default     = null
  description = "Optional SFTP authentication mode."

  validation {
    condition = try(
      var.sftp_authentication_methods == null ||
      contains(
        [
          "PASSWORD",
          "PUBLIC_KEY",
          "PUBLIC_KEY_OR_PASSWORD",
        ],
        var.sftp_authentication_methods
      ),
      true
    )
    error_message = "sftp_authentication_methods must be one of PASSWORD, PUBLIC_KEY, PUBLIC_KEY_OR_PASSWORD, or null."
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Banners
# ──────────────────────────────────────────────────────────────────────────────
variable "pre_authentication_login_banner" {
  type        = string
  default     = null
  description = "Banner shown before authentication."
}

variable "post_authentication_login_banner" {
  type        = string
  default     = null
  description = "Banner shown after authentication."
}

# ──────────────────────────────────────────────────────────────────────────────
# Logging (IAM decoupled)
# ──────────────────────────────────────────────────────────────────────────────
variable "logging_role_arn" {
  type        = string
  description = "IAM role ARN assumed by Transfer for CloudWatch logging (created outside this module)."
}

# ──────────────────────────────────────────────────────────────────────────────
# Users (IAM decoupled)
# ──────────────────────────────────────────────────────────────────────────────
variable "restricted_mode" {
  type        = bool
  default     = false
  description = "Lock users to logical home directories (LOGICAL) with mappings."
}

variable "users" {
  type = map(object({
    home_directory = string
    role_arn       = string # External IAM role (created in your IAM module)
    ssh_pub_keys   = list(string)
  }))
  default     = {}
  description = "Transfer users: home_directory, role_arn, and SSH public keys."
}

# ──────────────────────────────────────────────────────────────────────────────
# Workflows (IAM decoupled)
# ──────────────────────────────────────────────────────────────────────────────
variable "on_upload" {
  type = object({
    execution_role_arn = string
    workflow_id        = string
  })
  default     = null
  description = "Optional workflow to execute after a file is uploaded."
}

variable "on_partial_upload" {
  type = object({
    execution_role_arn = string
    workflow_id        = string
  })
  default     = null
  description = "Optional workflow to execute after a file is partially uploaded."
}

# ──────────────────────────────────────────────────────────────────────────────
# Host key safeguard (manage host identity via write-only API)
# ──────────────────────────────────────────────────────────────────────────────
# tflint-ignore: terraform_typed_variables,terraform_unused_declarations
variable "manage_host_keys" {
  type        = bool
  default     = false
  description = "If true, attach/import host key(s) to the server using write-only private keys."
}

# tflint-ignore: terraform_typed_variables,terraform_unused_declarations
variable "host_keys" {
  type = list(object({
    private_key = string # Sensitive; inject from CI/env
    description = optional(string)
  }))
  default     = []
  sensitive   = true
  description = "List of host keys to attach (private keys are write-only at the API)."
}

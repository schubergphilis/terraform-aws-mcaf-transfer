# ──────────────────────────────────────────────────────────────────────────────
# Core identifiers
# ──────────────────────────────────────────────────────────────────────────────
variable "name" {
  type        = string
  description = "A unique name for this transfer server instance. Used as the Name tag in the AWS Transfer Family console."

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9-]{0,62}$", var.name))
    error_message = "name must start with a letter and contain only letters, numbers, and hyphens, with a maximum length of 63 characters."
  }
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
# Protocols & security policy (FTP forbidden)
# ──────────────────────────────────────────────────────────────────────────────
variable "protocols" {
  description = "Enabled protocols (FTP is forbidden): any of SFTP, FTPS, AS2."
  type        = list(string)
  default     = ["SFTP"]
  validation {
    condition     = length(var.protocols) > 0 && alltrue([for p in var.protocols : contains(["SFTP", "FTPS", "AS2"], p)])
    error_message = "Protocols must be a non-empty list with elements in {SFTP, FTPS, AS2}. FTP is not allowed."
  }
}

variable "transfer_security_policy" {
  type = string
  # Choose a provider-supported policy your org approves.
  # Examples: TransferSecurityPolicy-2025-03, TransferSecurityPolicy-2024-01,
  # TransferSecurityPolicy-FIPS-2025-03, TransferSecurityPolicy-Restricted-2024-06
  default     = "TransferSecurityPolicy-2025-03"
  description = "Explicit AWS Transfer security policy name. Pin a current, provider-supported value to avoid drift and satisfy CKV_AWS_380."

  # Basic + hardened format check: require canonical prefix and a YYYY-MM suffix for year >= 2023.
  # (Allows FIPS/Restricted/PQ variants too.)
  validation {
    condition     = can(regex("^TransferSecurityPolicy(?:-[A-Za-z]+)?-20(2[3-9]|[3-9][0-9])-(0[1-9]|1[0-2])$", var.transfer_security_policy))
    error_message = "transfer_security_policy must look like TransferSecurityPolicy[-Variant]-YYYY-MM with year >= 2023 (e.g., TransferSecurityPolicy-2025-03 or TransferSecurityPolicy-FIPS-2025-03)."
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
    passive_ip                  = optional(string)       # FTPS passive-mode public IP
    tls_session_resumption_mode = optional(string)       # ENABLED | DISABLED (FTPS)
    set_stat_option             = optional(string)       # ENABLE_NO_OP | DISABLED (FTP-only; ignored since FTP is disallowed)
  })
  default     = null
  description = "Advanced protocol details; validated against protocol and identity settings. Note: FTP is disallowed by this module."
}

# ──────────────────────────────────────────────────────────────────────────────
# SFTP authentication (top-level; not part of protocol_details)
# ──────────────────────────────────────────────────────────────────────────────
variable "sftp_authentication_methods" {
  type        = string
  default     = null
  description = "Optional SFTP authentication mode. PASSWORD-only is forbidden. Valid only with identity_provider_type of API_GATEWAY or AWS_LAMBDA."

  validation {
    condition = try(
      var.sftp_authentication_methods == null ||
      contains(
        [
          # "PASSWORD",                # explicitly forbidden
          "PUBLIC_KEY",
          "PUBLIC_KEY_OR_PASSWORD",
        ],
        var.sftp_authentication_methods
      ),
      true
    )
    error_message = "sftp_authentication_methods must be one of PUBLIC_KEY, PUBLIC_KEY_OR_PASSWORD, or null. PASSWORD-only is not allowed."
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
# Custom hostname (console display / optional Route 53 integration)
# ──────────────────────────────────────────────────────────────────────────────

variable "custom_hostname" {
  type        = string
  default     = null
  description = "Optional custom DNS name to display in the AWS Transfer console Hostname column."

  # Simple DNS-safe validation
  validation {
    condition = (
      var.custom_hostname == null ||
      can(regex("^[a-zA-Z0-9.-]+$", var.custom_hostname))
    )
    error_message = "custom_hostname must contain only letters, numbers, dots, and hyphens."
  }
}

variable "route53_hosted_zone_id" {
  type        = string
  default     = null
  description = "Optional Route 53 hosted zone ID for the custom hostname."

  validation {
    condition = (
      # OK if unset
      var.route53_hosted_zone_id == null
      ||
      (
        # Must be valid ID format
        can(regex("^(/hostedzone/)?Z[A-Z0-9]+$", var.route53_hosted_zone_id))
        # And a hostname MUST be set if a zone is set
        && var.custom_hostname != null
      )
    )
    error_message = "If route53_hosted_zone_id is set, it must be a valid Route 53 zone ID and custom_hostname must also be provided."
  }
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

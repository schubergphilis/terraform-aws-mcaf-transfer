# terraform-aws-mcaf-transfer

Creates an AWS Transfer Family server and Transfer Family users (each with one or more SSH public keys).
IAM roles are **not** created by this module; callers must provide external IAM roles for logging and users.

## Example 1 — endpoint_type = "PUBLIC" (default)
```hcl
module "example-transfer" {
  source = "github.com/schubergphilis/terraform-aws-mcaf-transfer"

  name                     = "example"
  endpoint_type            = "PUBLIC" # default if omitted
  restricted_mode          = false
  tags                     = {}
  transfer_security_policy = "TransferSecurityPolicy-2025-03"

  # IAM role for CloudWatch logging (must be created externally)
  logging_role_arn = aws_iam_role.transfer_logging.arn

  users = {
    user1 = {
      home_directory = "/bucketname/user1"
      role_arn       = aws_iam_role.transfer_user_role.arn
      ssh_pub_keys   = ["key1", "key2"]
    }
  }
}
```

## Example 2 — endpoint_type = "VPC"
## The AWS Transfer Family service creates the VPC endpoint inside your VPC.
```hcl
module "example-transfer" {
  source = "github.com/schubergphilis/terraform-aws-mcaf-transfer"

  name                     = "example"
  endpoint_type            = "VPC"
  restricted_mode          = false
  tags                     = {}
  transfer_security_policy = "TransferSecurityPolicy-2025-03"

  logging_role_arn = aws_iam_role.transfer_logging.arn

  vpc_endpoint = {
    address_allocation_ids = ["eipalloc-12345", "eipalloc-67890"] # optional
    security_group_ids     = ["sg-12345678901234567"]
    subnet_ids             = ["subnet-12345", "subnet-67890"]
    vpc_id                 = "vpc-123456"
  }

  users = {
    user1 = {
      home_directory = "/bucketname/user1"
      role_arn       = aws_iam_role.transfer_user_role.arn
      ssh_pub_keys   = ["key1", "key2"]
    }
  }
}
```

## Example 3 — endpoint_type = "VPC_ENDPOINT"
## Use an existing VPC Endpoint (interface endpoint).
```hcl
module "example-transfer" {
  source = "github.com/schubergphilis/terraform-aws-mcaf-transfer"

  name                     = "example"
  endpoint_type            = "VPC_ENDPOINT"
  restricted_mode          = false
  tags                     = {}
  transfer_security_policy = "TransferSecurityPolicy-2025-03"

  logging_role_arn = aws_iam_role.transfer_logging.arn

  vpc_endpoint = {
    vpc_endpoint_id = "vpce-1234567890abcdef"
    # No security_group_ids, subnet_ids, or vpc_id allowed in VPC_ENDPOINT mode
  }

  users = {
    user1 = {
      home_directory = "/bucketname/user1"
      role_arn       = aws_iam_role.transfer_user_role.arn
      ssh_pub_keys   = ["key1", "key2"]
    }
  }
}
```

## Example 4
## identity_provider_type = "AWS_LAMBDA" with sftp_authentication_methods
```hcl
module "example-transfer" {
  source                   = "github.com/schubergphilis/terraform-aws-mcaf-transfer"
  name                     = "example-lambda-idp"

  endpoint_type            = "PUBLIC"
  restricted_mode          = false
  tags                     = {}
  transfer_security_policy = "TransferSecurityPolicy-2025-03"

  logging_role_arn = aws_iam_role.transfer_logging.arn

  identity_provider_type      = "AWS_LAMBDA"
  sftp_authentication_methods = "PUBLIC_KEY_OR_PASSWORD"

  identity_provider_details = {
    function_arn = aws_lambda_function.transfer_identity_provider.arn
  }

  users = {
    user1 = {
      home_directory = "/bucket/user1"
      role_arn       = aws_iam_role.transfer_user_role.arn
      ssh_pub_keys   = ["ssh-rsa AAAAB3Nz...", "ssh-ed25519 AAAAC3Nz..."]
    }
  }
}
```

## Example 5
## identity_provider_type = "API_GATEWAY" with PASSWORD-based authentication
```hcl
module "example-transfer" {
  source                   = "github.com/schubergphilis/terraform-aws-mcaf-transfer"
  name                     = "example-apigw-idp"

  endpoint_type            = "PUBLIC"
  restricted_mode          = false
  tags                     = {}
  transfer_security_policy = "TransferSecurityPolicy-2025-03"

  logging_role_arn = aws_iam_role.transfer_logging.arn

  identity_provider_type      = "API_GATEWAY"
  sftp_authentication_methods = "PASSWORD"

  identity_provider_details = {
    url             = "https://abc123.execute-api.eu-west-1.amazonaws.com/prod/auth"
    invocation_role = aws_iam_role.transfer_apigw_invoke.arn
  }

  users = {
    user1 = {
      home_directory = "/bucket/user1"
      role_arn       = aws_iam_role.transfer_user_role.arn
      ssh_pub_keys   = [] # optional if password-only auth is used
    }
  }
}
```

## Example 6
## identity_provider_type = "AWS_DIRECTORY_SERVICE"
## (sftp_authentication_methods must be null)
```hcl
module "example-transfer" {
  source                   = "github.com/schubergphilis/terraform-aws-mcaf-transfer"
  name                     = "example-directory-service"

  endpoint_type            = "PUBLIC"
  restricted_mode          = false
  tags                     = {}
  transfer_security_policy = "TransferSecurityPolicy-2025-03"

  logging_role_arn = aws_iam_role.transfer_logging.arn

  identity_provider_type      = "AWS_DIRECTORY_SERVICE"
  sftp_authentication_methods = null

  identity_provider_details = {
    directory_id = "d-1234567890"
  }

  users = {
    user1 = {
      home_directory = "/bucket/user1"
      role_arn       = aws_iam_role.transfer_user_role.arn
      ssh_pub_keys   = ["ssh-ed25519 AAAAC3Nz..."]
    }
  }
}
```

## Example 7
## protocols = ["FTPS"]
## FTPS passive mode configuration with TLS resumption
```hcl
module "example-transfer" {
  source                   = "github.com/schubergphilis/terraform-aws-mcaf-transfer"
  name                     = "example-ftps"

  endpoint_type            = "PUBLIC"
  restricted_mode          = false
  tags                     = {}
  transfer_security_policy = "TransferSecurityPolicy-2025-03"

  logging_role_arn = aws_iam_role.transfer_logging.arn

  protocols = ["FTPS"]

  protocol_details = {
    passive_ip                  = "198.51.100.42"
    tls_session_resumption_mode = "ENABLED"
  }

  users = {
    ftps_user = {
      home_directory = "/bucket/ftps"
      role_arn       = aws_iam_role.transfer_user_role.arn
      ssh_pub_keys   = []
    }
  }
}
```

## Example 8
## protocols = ["AS2"]
## AS2 over HTTP
```hcl
module "example-transfer" {
  source                   = "github.com/schubergphilis/terraform-aws-mcaf-transfer"
  name                     = "example-as2"

  endpoint_type            = "PUBLIC"
  restricted_mode          = false
  tags                     = {}
  transfer_security_policy = "TransferSecurityPolicy-2025-03"

  logging_role_arn = aws_iam_role.transfer_logging.arn

  protocols = ["AS2"]

  protocol_details = {
    as2_transports = ["HTTP"]
  }

  # AS2 users and partnerships are handled separately
  users = {}
}
```


## Example 9
## protocols = ["SFTP", "FTPS"]
## Mixed-mode SFTP + FTPS (passive IP applies only to FTPS)
```hcl
module "example-transfer" {
  source                   = "github.com/schubergphilis/terraform-aws-mcaf-transfer"
  name                     = "example-sftp-ftps"

  endpoint_type            = "PUBLIC"
  restricted_mode          = false
  tags                     = {}
  transfer_security_policy = "TransferSecurityPolicy-2025-03"

  logging_role_arn = aws_iam_role.transfer_logging.arn

  protocols = ["SFTP", "FTPS"]

  protocol_details = {
    passive_ip                  = "198.51.100.88"
    tls_session_resumption_mode = "ENABLED"
  }

  identity_provider_type      = "SERVICE_MANAGED"
  sftp_authentication_methods = null

  users = {
    user1 = {
      home_directory = "/bucket/user1"
      role_arn       = aws_iam_role.transfer_user_role.arn
      ssh_pub_keys   = ["ssh-ed25519 AAAAC3Nz..."]
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.100 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.100 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_transfer_server.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/transfer_server) | resource |
| [aws_transfer_ssh_key.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/transfer_ssh_key) | resource |
| [aws_transfer_tag.custom_hostname](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/transfer_tag) | resource |
| [aws_transfer_tag.route53_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/transfer_tag) | resource |
| [aws_transfer_user.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/transfer_user) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_logging_role_arn"></a> [logging\_role\_arn](#input\_logging\_role\_arn) | IAM role ARN assumed by Transfer for CloudWatch logging (created outside this module). | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | A unique name for this transfer server instance. Used as the Name tag in the AWS Transfer Family console. | `string` | n/a | yes |
| <a name="input_custom_hostname"></a> [custom\_hostname](#input\_custom\_hostname) | Optional custom DNS name to display in the AWS Transfer console Hostname column. | `string` | `null` | no |
| <a name="input_endpoint_type"></a> [endpoint\_type](#input\_endpoint\_type) | Endpoint type: PUBLIC \| VPC \| VPC\_ENDPOINT | `string` | `"PUBLIC"` | no |
| <a name="input_host_keys"></a> [host\_keys](#input\_host\_keys) | List of host keys to attach (private keys are write-only at the API). | <pre>list(object({<br/>    private_key = string # Sensitive; inject from CI/env<br/>    description = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_identity_provider_details"></a> [identity\_provider\_details](#input\_identity\_provider\_details) | Optional identity provider details; fields depend on identity\_provider\_type. | <pre>object({<br/>    function_arn    = optional(string) # For AWS_LAMBDA<br/>    invocation_role = optional(string) # For API_GATEWAY<br/>    url             = optional(string) # For API_GATEWAY<br/>    directory_id    = optional(string) # For AWS_DIRECTORY_SERVICE<br/>  })</pre> | `null` | no |
| <a name="input_identity_provider_type"></a> [identity\_provider\_type](#input\_identity\_provider\_type) | SERVICE\_MANAGED \| AWS\_LAMBDA \| API\_GATEWAY \| AWS\_DIRECTORY\_SERVICE | `string` | `"SERVICE_MANAGED"` | no |
| <a name="input_logging_policy"></a> [logging\_policy](#input\_logging\_policy) | DEPRECATED: Previously attached to an internal logging role. Provide an external logging\_role\_arn instead. | `string` | `"arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"` | no |
| <a name="input_manage_host_keys"></a> [manage\_host\_keys](#input\_manage\_host\_keys) | If true, attach/import host key(s) to the server using write-only private keys. | `bool` | `false` | no |
| <a name="input_on_partial_upload"></a> [on\_partial\_upload](#input\_on\_partial\_upload) | Optional workflow to execute after a file is partially uploaded. | <pre>object({<br/>    execution_role_arn = string<br/>    workflow_id        = string<br/>  })</pre> | `null` | no |
| <a name="input_on_upload"></a> [on\_upload](#input\_on\_upload) | Optional workflow to execute after a file is uploaded. | <pre>object({<br/>    execution_role_arn = string<br/>    workflow_id        = string<br/>  })</pre> | `null` | no |
| <a name="input_permissions_boundary"></a> [permissions\_boundary](#input\_permissions\_boundary) | DEPRECATED: Previously applied to IAM roles created by this module. Roles are now external. | `string` | `null` | no |
| <a name="input_post_authentication_login_banner"></a> [post\_authentication\_login\_banner](#input\_post\_authentication\_login\_banner) | Banner shown after authentication. | `string` | `null` | no |
| <a name="input_pre_authentication_login_banner"></a> [pre\_authentication\_login\_banner](#input\_pre\_authentication\_login\_banner) | Banner shown before authentication. | `string` | `null` | no |
| <a name="input_pre_login_banner"></a> [pre\_login\_banner](#input\_pre\_login\_banner) | DEPRECATED: Replaced by 'pre\_authentication\_login\_banner'. | `string` | `null` | no |
| <a name="input_protocol_details"></a> [protocol\_details](#input\_protocol\_details) | Advanced protocol details; validated against protocol and identity settings. Note: FTP is disallowed by this module. | <pre>object({<br/>    as2_transports              = optional(list(string)) # e.g., ["HTTP"] for AS2<br/>    passive_ip                  = optional(string)       # FTPS passive-mode public IP<br/>    tls_session_resumption_mode = optional(string)       # ENABLED | DISABLED (FTPS)<br/>    set_stat_option             = optional(string)       # ENABLE_NO_OP | DISABLED (FTP-only; ignored since FTP is disallowed)<br/>  })</pre> | `null` | no |
| <a name="input_protocols"></a> [protocols](#input\_protocols) | Enabled protocols (FTP is forbidden): any of SFTP, FTPS, AS2. | `list(string)` | <pre>[<br/>  "SFTP"<br/>]</pre> | no |
| <a name="input_restricted_mode"></a> [restricted\_mode](#input\_restricted\_mode) | Lock users to logical home directories (LOGICAL) with mappings. | `bool` | `false` | no |
| <a name="input_route53_hosted_zone_id"></a> [route53\_hosted\_zone\_id](#input\_route53\_hosted\_zone\_id) | Optional Route 53 hosted zone ID for the custom hostname. | `string` | `null` | no |
| <a name="input_sftp_authentication_methods"></a> [sftp\_authentication\_methods](#input\_sftp\_authentication\_methods) | Optional SFTP authentication mode. PASSWORD-only is forbidden. Valid only with identity\_provider\_type of API\_GATEWAY or AWS\_LAMBDA. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to assign to resources. Prefer provider default\_tags at root. | `map(string)` | `{}` | no |
| <a name="input_transfer_security_policy"></a> [transfer\_security\_policy](#input\_transfer\_security\_policy) | Explicit AWS Transfer security policy name. Pin a current, provider-supported value to avoid drift and satisfy CKV\_AWS\_380. | `string` | `"TransferSecurityPolicy-2025-03"` | no |
| <a name="input_users"></a> [users](#input\_users) | Transfer users: home\_directory, role\_arn, and SSH public keys. | <pre>map(object({<br/>    home_directory = string<br/>    role_arn       = string # External IAM role (created in your IAM module)<br/>    ssh_pub_keys   = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_vpc_endpoint"></a> [vpc\_endpoint](#input\_vpc\_endpoint) | Endpoint details depending on endpoint\_type. For VPC, set vpc\_id, subnet\_ids, security\_group\_ids[, address\_allocation\_ids]. For VPC\_ENDPOINT, set vpc\_endpoint\_id. | <pre>object({<br/>    address_allocation_ids = optional(list(string))<br/>    security_group_ids     = optional(list(string))<br/>    subnet_ids             = optional(list(string))<br/>    vpc_endpoint_id        = optional(string)<br/>    vpc_id                 = optional(string)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_logging_policy_deprecation"></a> [logging\_policy\_deprecation](#output\_logging\_policy\_deprecation) | Deprecation message for logging\_policy. |
| <a name="output_permissions_boundary_deprecation"></a> [permissions\_boundary\_deprecation](#output\_permissions\_boundary\_deprecation) | Deprecation message for permissions\_boundary. |
| <a name="output_pre_login_banner_deprecation"></a> [pre\_login\_banner\_deprecation](#output\_pre\_login\_banner\_deprecation) | Deprecation message for pre\_login\_banner. |
| <a name="output_server_arn"></a> [server\_arn](#output\_server\_arn) | ARN of the transfer server. |
| <a name="output_server_id"></a> [server\_id](#output\_server\_id) | Server ID (stable identifier; must not change). |
| <a name="output_user_arns"></a> [user\_arns](#output\_user\_arns) | ARNs of the transfer users. |
<!-- END_TF_DOCS -->

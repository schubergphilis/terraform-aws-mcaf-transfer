# terraform-aws-mcaf-transfer

Creates a transfer server and tranfer users (with one or more public SSH keys).

## Example 1 - the default
## endpoint_type = "PUBLIC"
```
module "example-transfer" {
  source                   = "github.com/schubergphilis/terraform-aws-mcaf-transfer"
  name                     = "example"

  endpoint_type            = "PUBLIC" # or do not provide, since it defaults to "PUBLIC"
  restricted_mode          = false
  tags                     = {}
  transfer_security_policy = "TransferSecurityPolicy-2020-06"

  users = {
    user1 = {
      home_directory = "/bucketname/user1"
      role_policy    = null
      ssh_pub_keys   = ["key1", "key2"]
    }
  }
}

```
## Example 2
## endpoint_type = "VPC"
##  By using this example the AWS Transfer Family service will create the VPC endpoint in the specified VPC.
```
module "example-transfer" {
  source                   = "github.com/schubergphilis/terraform-aws-mcaf-transfer"
  name                     = "example"

  endpoint_type            = "VPC"
  restricted_mode          = false
  tags                     = {}
  transfer_security_policy = "TransferSecurityPolicy-2020-06"

  vpc_endpoint = {
    address_allocation_ids = ["eipalloc-12345", "eipalloc-67890"] # or null
    security_group_ids     = ["sg-12345678901234567"]
    subnet_ids             = ["subnet-12345", "subnet-67890"]
    vpc_id                 = "vpc-123456"
  }

  users = {
    user1 = {
      home_directory = "/bucketname/user1"
      role_policy    = null
      ssh_pub_keys   = ["key1", "key2"]
    }
  }
}
```

## Example 3
## endpoint_type = "VPC_ENDPOINT"
##  By using this example you will make use of an already existing VPC Endpoint.
```
module "example-transfer" {
  source                   = "github.com/schubergphilis/terraform-aws-mcaf-transfer"
  name                     = "example"

  endpoint_type            = "VPC_ENDPOINT"
  restricted_mode          = false
  tags                     = {}
  transfer_security_policy = "TransferSecurityPolicy-2020-06"

  vpc_endpoint = {
    vpc_endpoint_id        = "vpc-endpoint-id-123456"
  }

  users = {
    user1 = {
      home_directory = "/bucketname/user1"
      role_policy    = null
      ssh_pub_keys   = ["key1", "key2"]
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
| [aws_transfer_user.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/transfer_user) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_logging_role_arn"></a> [logging\_role\_arn](#input\_logging\_role\_arn) | IAM role ARN assumed by Transfer for CloudWatch logging (created outside this module). | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | A unique name for this transfer server instance. | `string` | n/a | yes |
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
| <a name="input_protocol_details"></a> [protocol\_details](#input\_protocol\_details) | Advanced protocol details; validated against protocol and identity settings. | <pre>object({<br/>    as2_transports              = optional(list(string)) # e.g., ["HTTP"] for AS2<br/>    passive_ip                  = optional(string)       # FTPS/FTP passive-mode public IP<br/>    tls_session_resumption_mode = optional(string)       # ENABLED | DISABLED<br/>    set_stat_option             = optional(string)       # ENABLE_NO_OP | DISABLED<br/>  })</pre> | `null` | no |
| <a name="input_protocols"></a> [protocols](#input\_protocols) | Enabled protocols: any of SFTP, FTPS, FTP, AS2. | `list(string)` | <pre>[<br/>  "SFTP"<br/>]</pre> | no |
| <a name="input_restricted_mode"></a> [restricted\_mode](#input\_restricted\_mode) | Lock users to logical home directories (LOGICAL) with mappings. | `bool` | `false` | no |
| <a name="input_sftp_authentication_methods"></a> [sftp\_authentication\_methods](#input\_sftp\_authentication\_methods) | Optional SFTP authentication mode. | `string` | `null` | no |
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

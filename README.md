# terraform-aws-mcaf-transfer

Creates a transfer server and tranfer users (with one or more public SSH keys).

## Example SFTP Server with VPC endpoint
```
module "example-transfer" {
  source           = "github.com/schubergphilis/terraform-aws-mcaf-transfer"
  name             = "example"
  endpoint_type    = "VPC"
  tags             = {}
  restricted_mode = false
  s3_id = bucket-name # only when restricted_mode = true
  transfer_security_policy = "TransferSecurityPolicy-2020-06"
  endpoint_details = {
    address_allocation_ids = ["eipalloc-12345", "eipalloc-67890"]
    subnet_ids             = ["subnet-12345", "subnet-67890"]
    vpc_id                 = "vpc-123456"
  }

  users = {
    user1 = {
      home_directory = "homedir1"
      role_policy    = null
      ssh_pub_keys   = ["key1", "key2"]
    }
  }
}
```

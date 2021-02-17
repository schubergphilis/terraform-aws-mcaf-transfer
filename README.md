# terraform-aws-mcaf-transfer

Creates a transfer server and tranfer users (with one or more public SSH keys).

## Example
```
module "example-transfer" {
  source = "github.com/schubergphilis/terraform-aws-mcaf-transfer"
  name   = "example"
  tags   = {}
  users  = {
    user1 = {
      home_directory = "homedir1"
      role_policy    = null
      ssh_pub_keys   = ["key1", "key2"]
  endpoint_type          = "VPC"
  vpc_id                 = "vpc-123456"
  address_allocation_ids = ["eipalloc-12345", "eipalloc-67890"]
  subnet_ids             = ["subnet-12345", "subnet-67890"]
    }
  }
}
```

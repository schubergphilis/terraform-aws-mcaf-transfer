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

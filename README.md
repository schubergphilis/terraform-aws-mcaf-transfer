# terraform-aws-mcaf-transfer

Creates a transfer server and tranfer users (with one or more public SSH keys).

## Example
```
module "example-transfer" {
  source         = "github.com/schubergphilis/terraform-aws-mcaf-transfer"
  name           = "example"
  tags           = {}
  users = {
    user1 = {
      home_directory = "homedir1"
      role_policy = null
      ssh_pub_keys = ["key1", "key2"]
    }
  }
}
```

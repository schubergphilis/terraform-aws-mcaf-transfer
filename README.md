# terraform-aws-mcaf-transfer

Creates a transfer server, user and one or more public SSH keys.

Furthermore it creates a IAM role with attached role and log policy.

## Example
```
module "example-transfer" {
  source         = "github.com/schubergphilis/terraform-aws-mcaf-transfer?ref=v0.3.1"
  name           = "example"
  tags           = module.example_stack.tags
  ssh_pub_keys   =  ["ssh-rsa <KEY1>","ssh-rsa <KEY2>"]
  home_directory = "/<S3_BUCKET_NAME>"

}
```

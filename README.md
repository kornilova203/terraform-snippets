# [nat-gw](terraform/nat-gw)

Requires `key.pub` to exist in root of this repository.

After config is applied you can connect to ec2 instance with `ssh -i "path/to/private/key" ec2-user@<public ip of instance that can be found in aws console>`

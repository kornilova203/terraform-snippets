# [nat-gw](terraform/nat-gw)

Requires `key.pub` to exist in root of this repository.

After config is applied you can connect to ec2 instance with `ssh -i "path/to/private/key" ec2-user@<public ip of instance that can be found in aws console>`

How to access private instance:
1. Copy key file to public instance 
   ```
   cd path/to/private/key
   scp -i key key ec2-user@<public ip of public instance>:~/key
   ```
2. Connect to public instance `ssh -i key ec2-user@<public ip of public instance>`
3. From public instance connect to private `ssh -i key ec2-user@<private ip of private instance>`
4. Run `ping google.com` to make sure that NAT gateway works

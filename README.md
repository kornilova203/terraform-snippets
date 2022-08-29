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

# [transit-gw](terraform/transit-gw)

Creates two VPCs with one public subnet in each.
First VPC has an instance with public IP `public-instance1`, second VPC has an instance without public IP `private-instance2`.
Two VPCs are connected via transit gateway, so it's possible to reach private instance via a public one.

How to access private instance:
1. Copy key file to public instance
   ```
   cd path/to/private/key
   scp -i key key ec2-user@<public ip of public-instance1>:~/key
   ```
2. Connect to public instance `ssh -i key ec2-user@<public ip of public-instance1>`
3. From public instance connect to private `ssh -i key ec2-user@<private ip of private-instance2>`
# Integrate AWS with GCP

Recently, a question came to me. What if a legacy system/service has been used over years and it is built on AWS/GCP, and company would like to explore another cloud platform, how do we integrate services across different cloud platforms. This note is going to study how to build site-to-site VPN between AWS and GCP.  

## 📋 Prerequisites

The AWS services in this document include Customer Gateway, VPC, VPN, Transit Gateway, EC2(for test), and required GCP services include VM (for test), VPC, Cloud VPN, Firewall, and Reserved external IP. To save time, I just use admmin access for both platform. 

- AWS admin access
- GCP admin access

## 🏗️ Introduction

![aws-gcp-vpn-network-architecture.drawio](./aws-gcp-vpn-network-architecture.drawio.png)

From diagram above, what I would like to do is ec2/vm can ping each other, traffic goes from transit gateway, site-to-site vpn with customer gateway, to cloud vpn, and finally reach vm, and vice versa. Tasks are below:

  1. Reserve a static IP in GCP
  2. Create AWS VPC
  3. Create AWS Customer Gateway
  4. Create AWS Transit Gateway
  5. Create AWS Transit Gateway Attachment
  6. Create AWS Site-To-Site VPN
  7. Create AWS EC2
  8. Config route table of subnet
  9. Config Transit Gateway route table
  10. Create GCP VPC
  11. Create/Config Cloud VPN 
  12. Create GCP VM
  13. Config Network Firewall rule on GCP

finally, we can try to ping.

## ⚙️ Reserve GCP External IP

When I created customer gateway on AWS, it requires an external ip as entry point, but GCP cloud VPN is easier, it can config AWS public IP while creating service, so we have to start from reserving an external IP

#### 1. from GCP console, find VPC, find 'IP Address' from menu on the left-hand side, and click the button 'Reserve External Static IP Address' on the top
![where-find-ip-address](./where-find-ip-address.png)

## ⚙️ Create Resources on AWS

#### 2. AWS VPC

Create new VPC on AWS, we need a public subnet, with internet access, easier to ssh into EC2 server. My VPC config looks like:

<!-- ![new-vpc-config-1](./new-vpc-config-1.png)
![new-vpc-config-2](./new-vpc-config-2.png)
![new-vpc-config-3](./new-vpc-config-3.png) -->
<img src="./new-vpc-config-1.png" alt="new-vpc-config-1" width="50%"><br/>
<img src="./new-vpc-config-2.png" alt="new-vpc-config-2" width="50%"><br/>
<img src="./new-vpc-config-3.png" alt="new-vpc-config-3" width="50%"><br/>


### 3. AWS Customer Gateway

From VPC page, can find 'Customer gateways' from menu on left-hand side, click button 'Create customer gateway' on the top-right corner

![where-is-customer-gw](./where-is-customer-gw.png)

here is my customer gateway config, the value of 'IP address' should be the reserved IP from GCP<br/>
<!-- ![customer-gw-config](./customer-gw-config.png) -->
<img src="./customer-gw-config.png" alt="customer-gw-config" width="50%"><br/>

### 4. AWS Transit Gateway

From VPC page, can find 'Transit gateways' from menu on left-hand side, click button 'Create transit gateway' on the top-right corner
![where-is-tgw](./where-is-tgw.png)

here is my transit gateway config, I only use default values except Name tag<br/>
<!-- ![tgw-config-1](./tgw-config-1.png)
![tgw-config-2](./tgw-config-2.png) -->
<img src="./tgw-config-1.png" alt="tgw-config-1" width="50%"><br/>
<img src="./tgw-config-2.png" alt="tgw-config-2" width="50%"><br/>


and it may take a few minutes to finish.

### 5. AWS Transit Gateway Attachment

Under 'Transit gateways' on the left side menu, 'Transit gateway attachment' can be found easily. Here is my attachment config, I associate new VPC/Subnet from step 1 to TGW.<br/>

<!-- ![tgw-attachment-config-1](./tgw-attachment-config-1.png)
![tgw-attachment-config-2](./tgw-attachment-config-2.png)
![tgw-attachment-config-3](./tgw-attachment-config-3.png) -->
<img src="./tgw-attachment-config-1.png" alt="tgw-attachment-config-1" width="50%"><br/>
<img src="./tgw-attachment-config-2.png" alt="tgw-attachment-config-2" width="50%"><br/>
<img src="./tgw-attachment-config-3.png" alt="tgw-attachment-config-3" width="50%"><br/>

### 6. AWS Site-To-Site VPN

From VPC page, can find 'Site-to-Site VPN Connections' from menu on left-hand side, click button 'Create VPN connection' on the top-right corner

![where-is-sts-vpn](./where-is-sts-vpn.png)

Remember choose the transit gateway and VPC created in previous steps:<br/>

<!-- ![vpn-conn-config-1](./vpn-conn-config-1.png) -->
<img src="./vpn-conn-config-1.png" alt="vpn-conn-config-1" width="50%"><br/>

'Local IPv4', in this case, is the CIDR of GCP VPC, 'Remote IPv4' means the CIDR of AWS VPC <br/>
<!-- ![vpn-conn-config-2](./vpn-conn-config-2.png)
![vpn-conn-config-3](./vpn-conn-config-3.png) -->
<img src="./vpn-conn-config-2.png" alt="vpn-conn-config-2" width="50%"><br/>
<img src="./vpn-conn-config-3.png" alt="vpn-conn-config-3" width="50%"><br/>

expected result: <br/>
<!-- ![result-vpn-conn](./result-vpn-conn.png) -->
<img src="./result-vpn-conn.png" alt="result-vpn-conn" width="50%"><br/>

There are 2 tunnels on the bottom, status are all 'Down', it is correct, because we haven't created GCP cloud VPN yet. Also keep the 2 'Outside IP address', we will use them to config cloud VPN tunnel. 

Don't forget to download tunnel config, there is the button on the top-right corner:<br/>
<!-- ![download-vpn-tunnel-config](./download-vpn-tunnel-config.png) -->
<img src="./download-vpn-tunnel-config.png" alt="download-vpn-tunnel-config" width="50%"><br/>

The counterpart is GCP, we choose 'Generic' for Vendor and platform, but 'ike2' in IKE version.

![tunnel-config-1](./tunnel-config-1.png)
Look at the field 'Pre-Shared Key', we will need this value later. Find another pre-shared key!! we have 2 tunnels!!

### 7. AWS EC2

I don't give entire config to create EC2 server, only show network:

<!-- ![ec2-network-config-1](./ec2-network-config-1.png)
![ec2-network-config-2](./ec2-network-config-2.png) -->
<img src="./ec2-network-config-1.png" alt="ec2-network-config-1" width="50%"><br/>
<img src="./ec2-network-config-2.png" alt="ec2-network-config-2" width="50%"><br/>

Public IP just make my access to ec2 easiler, if you have baston server or client VPN, you can put this ec2 server in private subnet or without public IP.

Security group, I purposedly grant all traffic access to CIDR '11.0.0.0/16', which is GCP VPC/Subnet

### 8. Route Table of Subnet

Check subnet route table:<br/>
<!-- ![check-subnet-route-table](./check-subnet-route-table.png) -->
<img src="./check-subnet-route-table.png" alt="check-subnet-route-table" width="50%"><br/>

if there is no '11.0.0.0/16' (CIDR of GCP VPC), edit route table:<br/>
<!-- ![edit-subnet-route-table](./edit-subnet-route-table.png) -->
<img src="./edit-subnet-route-table.png" alt="edit-subnet-route-table" width="50%"><br/>

Target should be 'Transit Gateway', and value is the id of new tgw created just now.

### 9. Transit Gateway Route Table

Check tgw route associates:<br/>
<!-- ![check-tgw-route-table](./check-tgw-route-table.png) -->
<img src="./check-tgw-route-table.png" alt="check-tgw-route-table" width="50%"><br/>

this route association should have 2 attachments, 1 is VPC, another is our site-to-site VPN.

Check tgw route table, click tab 'Routes':
the complete route table should be:<br/>
![tgw-route-result](./tgw-route-result.png)

if it doesn't, create a new route connecting to VPN:<br/>
<!-- ![tgw-route-config](./tgw-route-config.png) -->
<img src="./tgw-route-config.png" alt="tgw-route-config" width="50%"><br/>



## ⚙️ Create Resources on GCP

### 10. GCP VPC

Click 'Create VPC Network' on the top
![where-is-gcp-vpc](./where-is-gcp-vpc.png)

here are my config:<br/>
<!-- ![gcp-vpc-config-1](./gcp-vpc-config-1.png)
![gcp-vpc-config-2](./gcp-vpc-config-2.png)
![gcp-vpc-config-3](./gcp-vpc-config-3.png)
![gcp-vpc-config-4](./gcp-vpc-config-4.png)
![gcp-vpc-config-5](./gcp-vpc-config-5.png) -->
<img src="./gcp-vpc-config-1.png" alt="gcp-vpc-config-1" width="50%"><br/>
<img src="./gcp-vpc-config-2.png" alt="gcp-vpc-config-2" width="50%"><br/>
<img src="./gcp-vpc-config-3.png" alt="gcp-vpc-config-3" width="50%"><br/>
<img src="./gcp-vpc-config-4.png" alt="gcp-vpc-config-4" width="50%"><br/>
<img src="./gcp-vpc-config-5.png" alt="gcp-vpc-config-5" width="50%"><br/>

### 11. Cloud VPN

Search 'VPN', let's start from 'Cloud VPN Gateway'
![where-is-vpn](./where-is-vpn.png)

This case only demonstrates 'Static Routing', not dynamic routing, use 'Classic VPN' 
![use-classic-vpn](./use-classic-vpn.png)

Choose correct VPC in 'Network', use reserved IP address in 'IP address'<br/>
<!-- ![gcp-tunnel-config-1](./gcp-tunnel-config-1.png) -->
<img src="./gcp-tunnel-config-1.png" alt="gcp-tunnel-config-1" width="50%"><br/>

we can find 'Remote peer IP address' from AWS VPN tunnel detail, we have 2 tunnels!!<br/>
<!-- ![gcp-tunnel-config-2](./gcp-tunnel-config-2.png)
![gcp-tunnel-config-3](./gcp-tunnel-config-3.png) -->
<img src="./gcp-tunnel-config-2.png" alt="gcp-tunnel-config-2" width="50%"><br/>
<img src="./gcp-tunnel-config-3.png" alt="gcp-tunnel-config-3" width="50%"><br/>

once its done, go back AWS VPN, we should see the result:
![aws-vpn-tunnel-up](./aws-vpn-tunnel-up.png)
the status is 'UP'

### 12. GCP VM

Search 'VM', and click button 'Create Instance'
![where-is-gcp-vm](./where-is-gcp-vm.png)

I don't give all details of gcp VM config, just show network detail, choose the GCP VPC created in previous step:<br/>
<!-- ![gcp-vm-network-config](./gcp-vm-network-config.png) -->
<img src="./gcp-vm-network-config.png" alt="gcp-vm-network-config" width="50%"><br/>

### 13. Network Firewall/Route on GCP

![where-is-gcp-vpc-firewall-rule](./where-is-gcp-vpc-firewall-rule.png)

1st rule is open ssh (port 22)

<!-- ![gcp-vpc-firewall-ssh-1](./gcp-vpc-firewall-ssh-1.png)
![gcp-vpc-firewall-ssh-2](./gcp-vpc-firewall-ssh-2.png)
![gcp-vpc-firewall-ssh-3](./gcp-vpc-firewall-ssh-3.png) -->
<img src="./gcp-vpc-firewall-ssh-1.png" alt="gcp-vpc-firewall-ssh-1" width="50%"><br/>
<img src="./gcp-vpc-firewall-ssh-2.png" alt="gcp-vpc-firewall-ssh-2" width="50%"><br/>
<img src="./gcp-vpc-firewall-ssh-3.png" alt="gcp-vpc-firewall-ssh-3" width="50%"><br/>

2nd rule is accept all traffic from '10.0.0.0/16', which is AWS VPC<br/>
<!-- ![gcp-vpc-firewall-all-traffic-1](./gcp-vpc-firewall-all-traffic-1.png)
![gcp-vpc-firewall-all-traffic-2](./gcp-vpc-firewall-all-traffic-2.png) -->
<img src="./gcp-vpc-firewall-all-traffic-1.png" alt="gcp-vpc-firewall-all-traffic-1" width="50%"><br/>
<img src="./gcp-vpc-firewall-all-traffic-2.png" alt="gcp-vpc-firewall-all-traffic-2" width="50%"><br/>

after creating gcp VPN and tunnels, routes should be added automatically, it should look like:
![gcp-vpn-tunnel-route](./gcp-vpn-tunnel-route.png)

if it doesn't show, may need to fix it manually:
create routes, click tab 'Route', and click the hyperlink 'route management'

![where-is-gcp-route-management](./where-is-gcp-route-management.png)

and create route here:<br/>
![create-gcp-route](./create-gcp-route.png)

Here is the detail of route config:<br/>
<!-- ![gcp-tunnel-route-config-1](./gcp-tunnel-route-config-1.png)
![gcp-tunnel-route-config-2](./gcp-tunnel-route-config-2.png) -->
<img src="./gcp-tunnel-route-config-1.png" alt="gcp-tunnel-route-config-1" width="50%"><br/>
<img src="./gcp-tunnel-route-config-2.png" alt="gcp-tunnel-route-config-2" width="50%"><br/>

we have 2 tunnel!!, don't forget do it again for 2nd tunnel.

## 🎆 Test Connectivity

SSH into AWS ec2 and GCP vm, ping each other!!

# Use AWS site-to-site VPN and connect to on-premise resource

Nowadays companies have several legacy systems, for various reasons, they cannot be migrated to cloud. I have encountered a few similar requests in projects. This document is going to study how to use Transit gateway and site-to-site VPN connecting to on-premise VPN.   

## 📋 Prerequisites

I install strongswan on GCP vm to simulate this scenario. 

- AWS admin access
- Install and config strongswan on GCP, refer to this <a href="https://github.com/ChaoChihLiu/study_nodes/tree/main/network/strongswan">document</a>
- AWS VPC CIDR: 172.31.0.0/16
- On-premise CIDR: 10.0.0.0/8

## 🏗️ Introduction
![aws connect to onpremise network architecture](./imgs/aws-onpremise-vpn-network-architecture.drawio.png)

Idea is to create customer gateway, site-to-site vpn and transit gateway to provide connectivity between AWS and on-premise server.

## ⚙️ Create simulation on GCP

Kindly refer to <a href="https://github.com/ChaoChihLiu/study_nodes/tree/main/network/strongswan">this document</a>

## ⚙️ Create Resources on AWS

### 1. AWS Customer Gateway

here is my customer gateway config, the value of 'IP address' should be the public IP of strongswan server
![customer-gw-config](./imgs/customer-gw-config.png)

### 2. AWS Transit Gateway

here is my transit gateway config, I only use default values except Name tag
![tgw-config-1](./imgs/tgw-config-1.png)
![tgw-config-2](./imgs/tgw-config-2.png)
and it may take a few minutes to finish.

### 3. AWS Transit Gateway Attachment and Site-to-Site VPN

Under 'Transit gateways' on the left side menu, 'Transit gateway attachment' can be found easily. Here is my attachment config, I associate new VPC/Subnet from step 1 to TGW.

Here is the VPC attachment config:
![tgw-attachment-config-1](./imgs/attachment-vpc.png)
Here is the VPN attachment config: 
![tgw-attachment-config-2](./imgs/attachment-vpn.png)
remember associate the customer gateway, created in previous step, to this attachment.

Also, site-to-site vpn will be created for you. 
expected result:
![site-to-site vpn](./imgs/site-to-site-vpn.jpg)

There is a 'Download' button on the top-right corner, download respective config to config strongswan:

![strongswan config](./imgs/tunnel-info.png)

Once strongswan on GCP has been created and run successfully, after few minutes, the tunnel information should be 'up'.In this case, we only use tunnel 1.

![tunnel status](./imgs/tunnel-status.jpg)



### 4. Route Table of VPC
I changed VPN route table, it will be applied to associated subnets if subnets has no its own route table. 

Check bpc route table:
![check-vpc-route-table](./imgs/check-vpc-route-table.png)

add new route to main table, associate on-premise CIDR with transit gateway created in previous steps.
![change-vpc-route-table](./imgs/change-vpc-route-table.png)

### 5. Transit Gateway Route Table

Check tgw route associates:
![check-tgw-route-table](./imgs/check-tgw-route-table.png)

this route association should have 2 attachments, 1 is VPC, we have to add site-to-site VPN to tgw route table.

expected result:
![check-tgw-route](./imgs/check-tgw-route.png)


### 6. Test connectivity

Create 1 GCP VM and 1 AWS EC2 in their respective VPC, and ping:

From AWS:<br/>
![from aws](./imgs/from-aws.png)

From on-premise: <br/>
![from gcp](./imgs/from-strongswan.png)
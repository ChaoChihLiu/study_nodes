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

here is my customer gateway config, the value of 'IP address' should be the public IP of strongswan server<br/>
<!-- ![customer-gw-config](./imgs/customer-gw-config.png) -->
<img src="./imgs/customer-gw-config.png" alt="customer-gw-config" width="50%"><br/>

### 2. AWS Transit Gateway

here is my transit gateway config, I only use default values except Name tag<br/>
<!-- ![tgw-config-1](./imgs/tgw-config-1.png)
![tgw-config-2](./imgs/tgw-config-2.png) -->
<img src="./imgs/tgw-config-1.png" alt="tgw-config-1" width="50%"><br/>
<img src="./imgs/tgw-config-2.png" alt="tgw-config-2" width="50%"><br/>
and it may take a few minutes to finish.

### 3. AWS Transit Gateway Attachment and Site-to-Site VPN

Under 'Transit gateways' on the left side menu, 'Transit gateway attachment' can be found easily. Here is my attachment config, I associate new VPC/Subnet from step 1 to TGW.

Here is the VPC attachment config:<br/>
<!-- ![tgw-attachment-config-1](./imgs/attachment-vpc.png) -->
<img src="./imgs/attachment-vpc.png" alt="tgw-attachment-config-1" width="50%"><br/>
Here is the VPN attachment config: <br/>
<!-- ![tgw-attachment-config-2](./imgs/attachment-vpn.png) -->
<img src="./imgs/attachment-vpn.png" alt="tgw-attachment-config-2" width="50%"><br/>
Here is the VPN attachment config: <br/>
remember associate the customer gateway, created in previous step, to this attachment.

Also, site-to-site vpn will be created for you. 
expected result:<br/>
<!-- ![site-to-site vpn](./imgs/site-to-site-vpn.jpg) -->
<img src="./imgs/site-to-site-vpn.jpg" alt="site-to-site vpn" width="50%"><br/>

There is a 'Download' button on the top-right corner, download respective config to config strongswan:<br/>

<!-- ![strongswan config](./imgs/tunnel-info.png)

![strongswan config detail](./imgs/tunnel-info-detail.png)
![strongswan secret key](./imgs/tunnel-secret-key.png) -->
<img src="./imgs/tunnel-info.png" alt="strongswan config" width="50%"><br/>
<img src="./imgs/tunnel-info-detail.png" alt="strongswan config detail" width="50%"><br/>
<img src="./imgs/tunnel-secret-key.png" alt="strongswan secret key" width="50%"><br/>

Once strongswan on GCP has been created and run successfully, after few minutes, the tunnel information should be 'up'.In this case, we only use tunnel 1.

![tunnel status](./imgs/tunnel-status.jpg)



### 4. Route Table of VPC
I changed VPN route table, it will be applied to associated subnets if subnets has no its own route table. 

Check bpc route table:<br/>
<!-- ![check-vpc-route-table](./imgs/check-vpc-route-table.png) -->
<img src="./imgs/check-vpc-route-table.png" alt="check-vpc-route-table" width="50%"><br/>

add new route to main table, associate on-premise CIDR with transit gateway created in previous steps.<br/>
<!-- ![change-vpc-route-table](./imgs/change-vpc-route-table.png) -->
<img src="./imgs/change-vpc-route-table.png" alt="change-vpc-route-table" width="50%"><br/>

you can find such tunnel information and secret key in this file downlowded from AWS; it can help you configure strongswan on-premise.

### 5. Transit Gateway Route Table

Check tgw route associates:<br/>
<!-- ![check-tgw-route-table](./imgs/check-tgw-route-table.png) -->
<img src="./imgs/check-tgw-route-table.png" alt="check-tgw-route-table" width="50%"><br/>

this route association should have 2 attachments, 1 is VPC, we have to add site-to-site VPN to tgw route table.

expected result:<br/>
<!-- ![check-tgw-route](./imgs/check-tgw-route.png) -->
<img src="./imgs/check-tgw-route.png" alt="check-tgw-route" width="50%"><br/>


### 6. Test connectivity

Create 1 GCP VM and 1 AWS EC2 in their respective VPC, and ping:

From AWS:<br/>
<!-- ![from aws](./imgs/from-aws.png) -->
<img src="./imgs/from-aws.png" alt="from aws" width="50%"><br/>
From on-premise: <br/>
<!-- ![from gcp](./imgs/from-strongswan.png) -->
<img src="./imgs/from-strongswan.png" alt="from gcp" width="50%"><br/>
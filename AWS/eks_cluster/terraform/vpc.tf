# Define the VPC
resource "aws_vpc" "eks_vpc" {
  cidr_block           = var.eks_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "eks-${var.env}-vpc"
  }
}

# Define the Internet Gateway (IGW) for the Public Subnet
resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "eks-bastion-${var.env}-igw"
  }
}

# Define a Route Table for the Public Subnet
resource "aws_route_table" "eks_bastion_rt" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "eks-${var.env}-public-route-table"
  }
}

# Add a route to the Internet Gateway in the Public Route Table
resource "aws_route" "eks_bastion_rt_route" {
  route_table_id         = aws_route_table.eks_bastion_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.eks_igw.id
}

# Define the Public Subnet

# Associate the Public Subnet with the Public Route Table
resource "aws_route_table_association" "eks_bastion_route_association" {
  subnet_id      = aws_subnet.eks_vpc_public_subnet.id
  route_table_id = aws_route_table.eks_bastion_rt.id
}

# Define the Private Subnets (3 Subnets)
resource "aws_subnet" "eks_frontend_subnet" {
  count                   = length(var.eks_azs)
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.eks_vpc.cidr_block, 8, count.index + 2) # Example: Adjust mask and index for subnets
  availability_zone       = element(var.eks_azs, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name = "eks-${count.index}-frontend-subnet"
  }
}
resource "aws_subnet" "eks_backend_subnet" {
  count                   = length(var.eks_azs)
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.eks_vpc.cidr_block, 8, count.index + 5) # Example: Adjust mask and index for subnets
  availability_zone       = element(var.eks_azs, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name = "eks-${count.index}-backend-subnet"
  }
}

resource "aws_subnet" "eks_vpc_public_subnet" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.eks_vpc_public_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "eks-${var.env}-vpc-public-subnet"
  }
}
# Create EIP for NAT Gateway
resource "aws_eip" "eks_nat_eip" {
  tags = {
    Name = "eks-${var.env}-nat-eip"
  }
}

# Create NAT Gateway in public subnet
resource "aws_nat_gateway" "eks_nat_gateway" {
  allocation_id = aws_eip.eks_nat_eip.id
  subnet_id     = aws_subnet.eks_vpc_public_subnet.id 

  tags = {
    Name = "eks-${var.env}-nat-gateway"
  }
}

resource "aws_route" "eks_vpc_nat_route" {
  route_table_id           = aws_vpc.eks_vpc.default_route_table_id  # Use the existing default route table for private subnets
  destination_cidr_block   = "0.0.0.0/0"  # Route all outbound traffic to the NAT Gateway
  nat_gateway_id           = aws_nat_gateway.eks_nat_gateway.id

  depends_on = [aws_nat_gateway.eks_nat_gateway]
}

# Create the RDS VPC
resource "aws_vpc" "rds_vpc" {
  cidr_block           = var.rds_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "rds-${var.env}-vpc"
  }
}

# Create private subnets for RDS 
resource "aws_subnet" "rds_private_subnets" {
  count                   = length(var.rds_azs)
  vpc_id                  = aws_vpc.rds_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.rds_vpc.cidr_block, 8, count.index + 1)  # Example CIDR block
  availability_zone       = var.rds_azs[count.index]
  map_public_ip_on_launch = false  # Private subnets should not have public IPs

  tags = {
    Name = "rds-private-subnet-${count.index}"
  }
}


resource "aws_vpc_peering_connection" "eks_to_rds_peering" {
  vpc_id        = aws_vpc.eks_vpc.id  # VPC ID of the EKS VPC
  peer_vpc_id   = aws_vpc.rds_vpc.id  # VPC ID of the RDS VPC
  auto_accept    = true  # Automatically accept the peering request on the peer side

  tags = {
    Name = "eks-to-rds-${var.env}-peering"
  }
}

resource "aws_route" "eks_to_rds_route" {
  route_table_id         = aws_vpc.eks_vpc.default_route_table_id  # Route table of EKS VPC
  destination_cidr_block = var.rds_vpc_cidr  # CIDR block of RDS VPC
  vpc_peering_connection_id = aws_vpc_peering_connection.eks_to_rds_peering.id

  depends_on = [aws_vpc_peering_connection.eks_to_rds_peering]
}

resource "aws_route" "eks_public_to_rds_route" {
  route_table_id         = aws_route_table.eks_bastion_rt.id  # Route table of EKS VPC
  destination_cidr_block = var.rds_vpc_cidr  # CIDR block of RDS VPC
  vpc_peering_connection_id = aws_vpc_peering_connection.eks_to_rds_peering.id

  depends_on = [aws_vpc_peering_connection.eks_to_rds_peering]
}


resource "aws_route" "rds_to_eks_route" {
  route_table_id         = aws_vpc.rds_vpc.default_route_table_id  # Route table of RDS VPC
  destination_cidr_block = var.eks_vpc_cidr  # CIDR block of EKS VPC
  vpc_peering_connection_id = aws_vpc_peering_connection.eks_to_rds_peering.id

  depends_on = [aws_vpc_peering_connection.eks_to_rds_peering]
}



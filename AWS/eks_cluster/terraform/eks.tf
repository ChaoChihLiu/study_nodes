resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg-${var.env}"
  description = "Allow all traffic within the VPC"
  vpc_id      = aws_vpc.eks_vpc.id

  ingress {
    description = "Allow all inbound traffic from within the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.eks_vpc.cidr_block]  # Allow all traffic within the VPC
  }

  ingress {
    description = "Allow SSH from Bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion_sg.id] # Allow access only from Bastion security group
  }


  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }
}


# Create EKS Cluster
resource "aws_eks_cluster" "eks_frontend" {
  name     = "eks-${var.env}-frontend-cluster"
  # role_arn = aws_iam_role.eks_cluster_role.arn
  role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/eksClusterRole"

  # VPC and Subnets
  vpc_config {
    subnet_ids = [for subnet in aws_subnet.eks_frontend_subnet : subnet.id] # Referencing private subnets in eks_vpc
    endpoint_public_access = true  # Enable access to the EKS control plane over public internet
    endpoint_private_access = true  # Private endpoint access
    security_group_ids     = [aws_security_group.eks_cluster_sg.id] 
  }

 enabled_cluster_log_types = ["api", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Project     = "eks-demo"
    Environment = var.env
  }
}
resource "aws_eks_cluster" "eks_backend" {
  name     = "eks-${var.env}-backend-cluster"
  # role_arn = aws_iam_role.eks_cluster_role.arn
  role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/eksClusterRole"

  # VPC and Subnets
  vpc_config {
    subnet_ids = [for subnet in aws_subnet.eks_backend_subnet : subnet.id] # Referencing private subnets in eks_vpc
    endpoint_public_access = false  # Enable access to the EKS control plane over public internet
    endpoint_private_access = true  # Private endpoint access
    security_group_ids     = [aws_security_group.eks_cluster_sg.id] 
  }

  enabled_cluster_log_types = ["api", "authenticator", "controllerManager", "scheduler"]
  

  tags = {
    Project     = "eks-demo"
    Environment = var.env
  }
}

# IAM Role for EKS Cluster
# resource "aws_iam_role" "eks_cluster_role" {
#   name = "eks-${var.env}-cluster-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = "eks.amazonaws.com"
#         }
#         Action = "sts:AssumeRole"
#       },
#     ]
#   })
# }

# # Attach the Amazon EKS Cluster Policy to the role
# resource "aws_iam_role_policy_attachment" "eks_cluster_role_policy" {
#   role       = aws_iam_role.eks_cluster_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
# }

# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node_role" {
  name = "eks-${var.env}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

# Attach necessary policies to EKS node role
resource "aws_iam_role_policy_attachment" "eks_node_role_worker_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_role_ec2_registry" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_node_role_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# EKS Node Group Configuration
resource "aws_eks_node_group" "eks_frontend_node_group" {
  cluster_name    = aws_eks_cluster.eks_frontend.name
  node_group_name = "eks-frontend-${var.env}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [for subnet in aws_subnet.eks_frontend_subnet : subnet.id] # Use private subnets for node group
  # security_group_ids = [aws_security_group.eks_node_sg.id]  # Attach the EKS node security group

  scaling_config {
    desired_size = var.node_desired_number
    max_size     = var.node_max_number
    min_size     = var.node_min_number
  }

  ami_type      = "AL2_x86_64" # Use Amazon Linux 2 EKS-optimized AMI
  instance_types = [var.frontend_node_type] # Instance type for worker nodes

  tags = {
    Project     = "eks-demo"
    Environment = var.env
  }
}

resource "aws_eks_node_group" "eks_backend_node_group" {
  cluster_name    = aws_eks_cluster.eks_backend.name
  node_group_name = "eks-backend-${var.env}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [for subnet in aws_subnet.eks_backend_subnet : subnet.id] # Use private subnets for node group
  # security_group = [aws_security_group.eks_node_sg]  # Attach the EKS node security group

  scaling_config {
    desired_size = var.node_desired_number
    max_size     = var.node_max_number
    min_size     = var.node_min_number
  }

  ami_type      = "AL2_x86_64" # Use Amazon Linux 2 EKS-optimized AMI
  instance_types = [var.backend_node_type] # Instance type for worker nodes

  tags = {
    Project     = "eks-demo"
    Environment = var.env
  }
}

# resource "aws_security_group" "eks_node_sg" {
#   name        = "eks-node-sg-${var.env}"
#   description = "Allow SSH access from Bastion server"
#   vpc_id      = aws_vpc.eks_vpc.id

#   ingress {
#     description = "Allow SSH from Bastion"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     security_groups = [aws_security_group.bastion_sg.id] # Allow access only from Bastion security group
#   }

#   ingress {
#     description = "Allow all traffic within the VPC"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "tcp"
#     cidr_blocks = [aws_vpc.eks_vpc.cidr_block]  # Allow all traffic within the VPC
#   }

#   egress {
#     description = "Allow all outbound traffic"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
#   }

#   tags = {
#     Name = "eks-node-sg-${var.env}"
#   }
# }


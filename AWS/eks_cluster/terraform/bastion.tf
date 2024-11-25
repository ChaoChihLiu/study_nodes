# Bastion Host Security Group
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-${var.env}-sg"
  description = "Allow SSH access to the bastion server"
  vpc_id      = aws_vpc.eks_vpc.id  # Referencing the eks_vpc created earlier

  ingress {
    description = "Allow SSH"
    from_port   = var.bastion_allow_access_ports
    to_port     = var.bastion_allow_access_ports
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with your public IP or CIDR block
  }

  ingress {
    description = "Allow all traffic within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # All protocols
    cidr_blocks = [var.eks_vpc_cidr] # VPC CIDR
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-${var.env}-sg"
  }
}

# Bastion Host EC2 Instance
resource "aws_instance" "bastion" {
  ami                         = var.bastion_ami_id
  instance_type               = var.bastion_instance_type
  subnet_id                   = aws_subnet.eks_vpc_public_subnet.id  # Use the public subnet of eks_vpc
  associate_public_ip_address = true  # Ensures the instance gets a public IP
  key_name                    = var.bastion_key_pair_name  # SSH key to access the instance

  iam_instance_profile = aws_iam_instance_profile.ec2_access_eks_profile.name
  # Associate the bastion security group
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  # Disable termination from the AWS Console
  disable_api_termination = var.disable_api_termination

  # User data for instance initialization
  user_data = <<-EOF
  #!/bin/bash
  # Set timezone
  sudo timedatectl set-timezone 'Asia/Singapore'

  echo "Updating package lists"
  sudo yum update -y

  # Install necessary packages
  echo "Installing packages: Amazon Corretto JDK, curl, gnupg, and nginx"
  sudo yum install -y java-17-amazon-corretto curl gnupg nginx

  # Install kubectl
  echo "Installing packages: kubectl"
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/

  echo "Finished to install kubectl"
EOF


  tags = {
    Name = "bastion-${var.env}-ec2"
  }
}

resource "aws_iam_role" "ec2_access_eks" {
  name = "ec2_access_eks-${var.env}" # Role name with environment suffix

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com" # Allow EC2 instances to assume this role
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "ec2_access_eks-${var.env}"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.ec2_access_eks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.ec2_access_eks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_instance_profile" "ec2_access_eks_profile" {
  name = "ec2_access_eks-instance-profile-${var.env}"
  role = aws_iam_role.ec2_access_eks.name
}

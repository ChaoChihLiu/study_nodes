# Create MySQL 8 RDS Cluster
# resource "aws_rds_cluster" "mysql_rds_cluster" {
#   cluster_identifier       = "eks-${var.env}-mysql-cluster"
#   engine                   = "mysql"
#   engine_version           = "8.0"
#   master_username          = var.rds_username
#   master_password          = var.rds_password
#   db_subnet_group_name     = aws_db_subnet_group.rds_subnet_group.name
#   availability_zones       = var.rds_azs
#   storage_encrypted        = true
#   backup_retention_period  = 7
#   skip_final_snapshot      = false
#   final_snapshot_identifier = "eks-${var.env}-mysql-cluster-final-snapshot"

#   tags = {
#     Name = "eks-${var.env}-mysql-rds-cluster"
#   }
# }

# RDS Cluster Instance (for multi-az)
# resource "aws_rds_cluster_instance" "mysql_rds_instance" {
#   for_each                = toset(var.rds_azs)
#   cluster_identifier = "${aws_rds_cluster.mysql_rds_cluster.id}-${each.key}"
#   instance_class     = "db.m5.large"  # Example instance class (you can adjust as needed)
#   engine             = "mysql"
#   engine_version     = "8.0"
#   publicly_accessible = false  # Keep it private

#   tags = {
#     Name = "eks-${var.env}-mysql-rds-instance"
#   }
# }


resource "aws_db_instance" "rds_instance" {
  allocated_storage    = var.rds_storage_size              # 20GB storage
  engine               = "mysql"          # MySQL database
  engine_version       = "8.0"            # MySQL 8.0
  instance_class       = var.rds_instance_type  # Cost-effective test instance
  identifier           = "eks-${var.env}-rds"         # Database name
  username             = var.rds_username    # Master username
  password             = var.rds_password  # Master password
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot  = true             # Skip final snapshot when deleting

  tags = {
     Name = "eks-${var.env}-mysql-rds"
  }
}

# Create a subnet group for RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-private-subnet-group"
  subnet_ids = [for subnet in aws_subnet.rds_private_subnets : subnet.id]

  tags = {
    Name = "rds-${var.env}-private-subnet-group"
  }
}

# RDS Security Group
resource "aws_security_group" "rds_sg" {
  name        = "rds-${var.env}-sg"
  description = "Allow access to RDS server from EKS"
  vpc_id      = aws_vpc.rds_vpc.id

  ingress {
    description = "Allow DB connection from EKS security group"
    from_port   = var.rds_allow_access_ports
    to_port     = var.rds_allow_access_ports
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.eks_vpc.cidr_block]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

profile = "aws_terraform"
region     = "ap-northeast-1"
env        = "dev28"

eks_vpc_cidr = "10.1.0.0/16"
eks_vpc_public_subnet_cidr = "10.1.1.0/24"
eks_azs    = ["ap-northeast-1a", "ap-northeast-1d", "ap-northeast-1c"]

frontend_node_type = "t3.xlarge"
backend_node_type = "t3.xlarge"


bastion_ami_id = "ami-094dc5cf74289dfbc"
bastion_instance_type = "t3.micro"
bastion_subnet_cidr = "10.1.5.0/24"
bastion_key_pair_name = "tokyo-dr-sz"
bastion_allow_access_ports = "22"
# bastion_subnet_az    = "ap-northeast-1c"
disable_api_termination = false

rds_username     = "testuser"
rds_vpc_cidr     = "10.2.0.0/16"
rds_azs          = ["ap-northeast-1a", "ap-northeast-1d", "ap-northeast-1c"]
rds_allow_access_ports = "3306"
rds_storage_size = 20
# rds_instance_type = "db.m5d.large"
rds_instance_type = "db.t3.micro"  


node_max_number = 6
node_min_number = 1
node_desired_number = 4


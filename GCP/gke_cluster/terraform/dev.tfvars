region     = "asia-southeast1"
env        = "dev2"

frontend_subnet_cidr = "10.1.1.0/24"
frontend_source_ranges_cidr = ["10.1.1.0/24"]
frontend_gke_allow_inbound_ports = ["443", "80", "8443", "8080"]
frontend_node_type = "e2-standard-4"
#master_ipv4_cidr_block is a reserved range for internal communication between the control plane and the nodes,
#and it needs to be unique to avoid IP conflicts.
#The range must be at least /28
frontend_control_panel_cidr = "10.1.3.0/28"

backend_subnet_cidr = "10.1.2.0/24"
backend_source_ranges_cidr = ["10.1.2.0/24"]
backend_gke_allow_inbound_ports = ["443", "80", "8443", "8080"]
backend_node_type = "e2-standard-4"
#master_ipv4_cidr_block is a reserved range for internal communication between the control plane and the nodes,
#and it needs to be unique to avoid IP conflicts.
#The range must be at least /28
backend_control_panel_cidr = "10.1.4.0/28"

bastion_subnet_cidr = "10.1.5.0/24"
bastion_source_ranges_cidr = ["10.1.5.0/24"]
bastion_allow_access_ports = ["22"]
bastion_vm_zone    = "asia-southeast1-c"
bastion_deletion_protection = false

sql_username     = "testuser"
sql_instance_version = "POSTGRES_15"
sql_instance_type = "db-custom-1-3840" #db-custom-{cpu}-{memory}
sql_storage_size = "20"
sql_deletion_protection = false
sql_ha_type = "ZONAL" #ZONAL or REGIONAL

gke_location = "asia-southeast1-a" #can be asia-southeast1, here I only give a zonal gke cluster
node_max_number = 6


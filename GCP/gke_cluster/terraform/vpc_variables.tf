variable "frontend_subnet_cidr" {
  description = "cidr range for frontend subnet"
  type        = string
}

variable "backend_subnet_cidr" {
  description = "cidr range for backend subnet"
  type        = string
}

variable "frontend_source_ranges_cidr" {
  description = "array of tags in backend subnet firewall rule"
  type        = list(string)
}

variable "backend_source_ranges_cidr" {
  description = "array of tags in backend subnet firewall rule"
  type        = list(string)
}

variable "backend_gke_allow_inbound_ports" {
  description = "allow inbound ports to access backend cluster"
  type        = list(string)
  default = ["443", "8081", "8080"]
}

variable "frontend_gke_allow_inbound_ports" {
  description = "allow inbound ports to access frontend cluster"
  type        = list(string)
  default = ["443", "9090"]
}

# use dev.tfvars (prod.tfvars) to define variable value
# a sample .tfvars should look like:
#
# project_id = "XXXX"
# region     = "XXXX"


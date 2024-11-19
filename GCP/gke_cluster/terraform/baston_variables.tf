variable "bastion_subnet_cidr" {
  description = "cidr range for bastion subnet"
  type        = string
}

variable "bastion_vm_zone" {
  description = "which zone bastion vm sits"
  type        = string
}

variable "vm_access_key" {
  description = "ssh access key"
  type        = string
  sensitive   = true
}

variable "vm_ssh_username" {
  description = "ssh access username"
  type        = string
  sensitive   = true
}

variable "bastion_deletion_protection" {
  description = "Whether to enable deletion protection for the bastion instance"
  type        = bool
  default     = false
}

variable "bastion_allow_access_ports" {
  description = "array of ports, allow public access"
  type        = list(string)
  default     = ["22"]
}


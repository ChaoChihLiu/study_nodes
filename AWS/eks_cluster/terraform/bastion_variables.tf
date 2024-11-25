variable "bastion_ami_id" {
  description = "bastion ami id"
  type        = string
}

variable "bastion_key_pair_name" {
  description = "key pair for ssh, have to be created beforehand"
  type        = string
}

variable "bastion_allow_access_ports" {
  description = "array of ports, allow public access"
  type        = string
  default     = "22"
}

variable "bastion_instance_type" {
    description = "bastion EC2 instance type"
    type        = string
    default     = "t3a.micro"
}

variable "disable_api_termination" {
    description = "allow to terminate bastion server with api"
    type        = bool
    default     = false
}
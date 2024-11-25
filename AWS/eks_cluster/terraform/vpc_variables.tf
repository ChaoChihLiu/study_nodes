variable "eks_vpc_cidr" {
  description = "vpc eks cidr"
  type        = string
  default = "10.1.0.0/16"
}

variable "eks_vpc_public_subnet_cidr" {
  description = "vpc public subnet cidr"
  type        = string
  default = "10.1.1.0/24"
}

variable "eks_azs" {
  description = "which az will be used"
  type        = list(string)
}

variable "rds_vpc_cidr" {
  description = "rds vpc cidr"
  type        = string
  default = "10.2.0.0/16"
}

variable "rds_azs" {
  description = "which az will be used"
  type        = list(string)
}


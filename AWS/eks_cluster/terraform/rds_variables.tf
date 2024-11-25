variable "rds_allow_access_ports" {
    description = "the port allows access"
    type        = string
    default     = "3306"
}

variable "rds_username" {
    description = "rds user name"
    type        = string
    default     = "admin"
}

variable "rds_password" {
    description = "rds password"
    type        = string
}

variable "rds_storage_size" {
    description = "rds storage size"
    type        = number
    default = 20
}

variable "rds_instance_type" {
    description = "rds instance type"
    type        = string
    default = "db.m5d.large"
}
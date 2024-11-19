variable "sql_username" {
  description = "The username for the PostgreSQL database"
  type        = string
}

variable "sql_password" {
  description = "The password for the PostgreSQL database"   //use environment variable to set it: export TF_VAR_sql_password="XXXX"
  type        = string
  sensitive   = true
}

variable "sql_instance_version" {
  description = "The version for the PostgreSQL database"
  type        = string
  default = "POSTGRES_15"
}

variable "sql_instance_type" {
  description = "The tier type for the PostgreSQL database"
  type        = string
  default = "db-g1-small"
}

variable "sql_deletion_protection" {
  description = "Whether to enable deletion protection for the database instance"
  type        = bool
  default     = true
}

variable "sql_storage_size" {
  description = "db storage size"
  type        = string
  default     = "20"
}

variable "sql_ha_type" {
  description = "database HA or only 1 zone"
  type        = string
  default     = "ZONAL"
}

#variable "sql_subnet_cidr" {
#  description = "db cidr"
#  type        = string
#  default     = "20"
#}

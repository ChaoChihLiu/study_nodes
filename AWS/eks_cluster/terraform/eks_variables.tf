variable "node_desired_number" {
    description = "desired cluster size"
    type        = number
    default     = 4
}

variable "node_max_number" {
    description = "maximum cluster size"
    type        = number
    default     = 6
}

variable "node_min_number" {
    description = "minum cluster size"
    type        = number
    default     = 1
}

variable "frontend_node_type" {
    description = "node instance type"
    type        = string
    default     = "t3.xlarge"
}

variable "backend_node_type" {
    description = "node instance type"
    type        = string
    default     = "t3.xlarge"
}
variable "backend_control_panel_cidr" {
  description = "backend control panel ipv4 cidr block"
  type        = string
}

variable "frontend_control_panel_cidr" {
  description = "frontend control panel ipv4 cidr block"
  type        = string
}

variable "gke_location" {
  description = "zonal or regional gke, if regional gke is required, give region code, or give zone code"
  type        = string
  default = "asia-southeast1-a"
}

variable "node_max_number" {
  description = "max nodes in gke cluster"
  type        = number
  default = 5
}

variable "backend_node_type" {
  description = "backend cluster node machine type"
  type        = string
}

variable "frontend_node_type" {
  description = "frontend cluster node machine type"
  type        = string
}
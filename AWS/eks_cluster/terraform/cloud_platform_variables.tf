# use dev.tfvars (prod.tfvars) to define variable value
# a sample .tfvars should look like:
#
# project_id = "XXXX"
# region     = "XXXX"

variable "profile" {
  description = "aws profile"
  type        = string
}

variable "region" {
  description = "region"
  type        = string
  default     = "asia-southeast1"
}

variable "env" {
  description = "system environment, i.e. dev, uat, prod"
  type        = string
}



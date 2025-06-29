# Variables for main.tf

variable "cross_account_destination" {
  description = "Destination account ID for cross-account backup"
  type        = string
}

variable "db_subnet_ids" {
  description = "Subnet IDs for the RDS instance"
  type        = list(string)
}

variable "db_security_group_ids" {
  description = "Security group IDs for the RDS instance"
  type        = list(string)
}

variable "db_password" {
  description = "Password for the RDS instance"
  type        = string
  sensitive   = true
}

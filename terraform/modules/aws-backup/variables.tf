# AWS Backup Terraform Module
# Scenario #4: Comprehensive backup solution with cross-region, cross-account, and WORM protection

# Variables
variable "backup_vault_name" {
  description = "Name of the backup vault"
  type        = string
  default     = "allianz-trade-backup-vault"
}

variable "backup_plan_name" {
  description = "Name of the backup plan"
  type        = string
  default     = "allianz-trade-backup-plan"
}

variable "kms_key_id" {
  description = "KMS key ID for backup encryption"
  type        = string
}

variable "cross_region_destination" {
  description = "Destination region for cross-region backup"
  type        = string
  default     = "eu-central-1"
}

variable "cross_account_destination" {
  description = "Destination account ID for cross-account backup"
  type        = string
}

variable "vault_lock_days" {
  description = "Number of days for vault lock (WORM protection)"
  type        = number
  default     = 7
}

variable "backup_frequency" {
  description = "Backup frequency in cron format"
  type        = string
  default     = "cron(0 2 * * ? *)" # Daily at 2 AM
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 365
}

variable "cross_region_retention_days" {
  description = "Cross-region backup retention period in days"
  type        = number
  default     = 90
}

variable "cross_account_retention_days" {
  description = "Cross-account backup retention period in days"
  type        = number
  default     = 2555 # 7 years for compliance
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
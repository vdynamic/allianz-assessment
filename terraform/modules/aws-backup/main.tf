# Backup Vault
resource "aws_backup_vault" "primary" {
  name        = var.backup_vault_name
  kms_key_arn = var.kms_key_id
  tags        = var.tags
}

# Backup Plan
resource "aws_backup_plan" "comprehensive" {
  name = var.backup_plan_name

  rule {
    rule_name         = "daily_backups"
    target_vault_name = aws_backup_vault.primary.name
    schedule          = var.backup_frequency

    lifecycle {
      delete_after = var.backup_retention_days
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.cross_region.arn
      lifecycle {
        delete_after = var.cross_region_retention_days
      }
    }

    copy_action {
      destination_vault_arn = "arn:aws:backup:${var.cross_region_destination}:${var.cross_account_destination}:backup-vault:${var.backup_vault_name}"
      lifecycle {
        delete_after = var.cross_account_retention_days
      }
    }
  }

  tags = var.tags
}

# Backup Vault for cross-region replication
resource "aws_backup_vault" "cross_region" {
  provider    = aws.cross_region
  name        = var.backup_vault_name
  kms_key_arn = var.kms_key_id
  tags        = var.tags
}

# Backup Vault Lock
resource "aws_backup_vault_lock_configuration" "primary" {
  backup_vault_name   = aws_backup_vault.primary.name
  min_retention_days  = var.vault_lock_days
  changeable_for_days = 0
}

# Backup Selection
resource "aws_backup_selection" "by_tag" {
  iam_role_arn = aws_iam_role.backup_service.arn
  name         = "by_tag"
  plan_id      = aws_backup_plan.comprehensive.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "ToBackup"
    value = "true"
  }
}

# IAM Role for AWS Backup
resource "aws_iam_role" "backup_service" {
  name = "aws_backup_service_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup",
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestore"
  ]
}

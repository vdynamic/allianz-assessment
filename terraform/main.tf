module "aws_backup" {
  source = "../modules/aws-backup"

  # Required providers
  providers = {
    aws.cross_region = aws.cross_region
  }

  # Configuration
  backup_vault_name           = "allianz-trade-primary-vault"
  backup_plan_name           = "allianz-trade-comprehensive-backup"
  kms_key_id                 = aws_kms_key.backup_encryption.arn
  cross_region_destination   = "eu-central-1"
  cross_account_destination  = "123456789012" # Replace with actual account ID
  
  # Backup schedule and retention
  backup_frequency             = "cron(0 2 * * ? *)" # Daily at 2 AM
  backup_retention_days        = 365                  # 1 year
  cross_region_retention_days  = 90                   # 3 months
  cross_account_retention_days = 2555                 # 7 years

  # WORM protection
  vault_lock_days = 7

  # Common tags
  tags = {
    Owner       = "cloudfoundation@allianz-trade.com"
    Environment = "production"
    Compliance  = "required"
  }
}
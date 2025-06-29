# KMS key for backup encryption
resource "aws_kms_key" "backup_encryption" {
  description             = "KMS key for encrypting backups"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "allianz-trade-backup-key"
  }
}

resource "aws_kms_alias" "backup_encryption" {
  name          = "alias/allianz-trade-backup-key"
  target_key_id = aws_kms_key.backup_encryption.id
}

module "aws_backup" {
  source = "../modules/aws-backup"

  # Required providers
  providers = {
    aws.cross_region = aws.cross_region
  }

  # Configuration
  backup_vault_name         = "allianz-trade-primary-vault"
  backup_plan_name          = "allianz-trade-comprehensive-backup"
  kms_key_id                = aws_kms_key.backup_encryption.arn
  cross_region_destination  = "eu-central-1"
  cross_account_destination = var.cross_account_destination

  # Backup schedule and retention
  backup_frequency             = "cron(0 2 * * ? *)" # Daily at 2 AM
  backup_retention_days        = 365                 # 1 year
  cross_region_retention_days  = 90                  # 3 months
  cross_account_retention_days = 2555                # 7 years

  # WORM protection
  vault_lock_days = 7

  # Common tags
  tags = {
    Owner       = "cloudfoundation@allianz-trade.com"
    Environment = "production"
    Compliance  = "required"
  }
}

resource "aws_s3_bucket" "example" {
  bucket = "allianz-trade-example-data-bucket"

  tags = {
    ToBackup = "true"
    Owner    = "dataengineering@eulerhermes.com"
  }
}

resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.backup_encryption.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Example RDS instance
resource "aws_db_subnet_group" "example" {
  name       = "allianz-trade-example-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "Allianz Trade Example DB subnet group"
  }
}

resource "aws_secretsmanager_secret" "db_password" {
  name = "allianz-trade-db-password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

resource "aws_db_instance" "example" {
  identifier     = "allianz-trade-example-db"
  engine         = "postgres"
  engine_version = "14.9"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.backup_encryption.arn

  db_name  = "exampledb"
  username = "adminuser"
  password = aws_secretsmanager_secret_version.db_password.secret_string

  db_subnet_group_name   = aws_db_subnet_group.example.name
  vpc_security_group_ids = var.db_security_group_ids

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    ToBackup = "true"
    Owner    = "database@eulerhermes.com"
  }
}

# Example DynamoDB table
resource "aws_dynamodb_table" "example" {
  name         = "allianz-trade-example-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.backup_encryption.arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    ToBackup = "true"
    Owner    = "application@eulerhermes.com"
  }
}

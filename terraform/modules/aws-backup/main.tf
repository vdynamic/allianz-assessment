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
  subnet_ids = ["subnet-12345678", "subnet-87654321"] # Replace with actual subnet IDs

  tags = {
    Name = "Allianz Trade Example DB subnet group"
  }
}

resource "aws_db_instance" "example" {
  identifier     = "allianz-trade-example-db"
  engine         = "postgres"
  engine_version = "14.9"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true
  kms_key_id           = aws_kms_key.backup_encryption.arn
  
  db_name  = "exampledb"
  username = "adminuser"
  password = "changeme123!" # Use AWS Secrets Manager in production
  
  db_subnet_group_name   = aws_db_subnet_group.example.name
  vpc_security_group_ids = ["sg-12345678"] # Replace with actual security group ID
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = true
  deletion_protection = false
  
  tags = {
    ToBackup = "true"
    Owner    = "database@eulerhermes.com"
  }
}

# Example DynamoDB table
resource "aws_dynamodb_table" "example" {
  name           = "allianz-trade-example-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  
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

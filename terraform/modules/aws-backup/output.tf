# Outputs
output "backup_vault_arn" {
  description = "ARN of the primary backup vault"
  value       = module.aws_backup.backup_vault_arn
}

output "backup_plan_id" {
  description = "ID of the backup plan"
  value       = module.aws_backup.backup_plan_id
}

output "example_resources" {
  description = "Example resources that will be backed up"
  value = {
    s3_bucket     = aws_s3_bucket.example.id
    rds_instance  = aws_db_instance.example.identifier
    dynamodb_table = aws_dynamodb_table.example.name
  }
}
# Outputs
output "backup_vault_arn" {
  description = "ARN of the primary backup vault"
  value       = aws_backup_vault.primary.arn
}

output "backup_plan_id" {
  description = "ID of the backup plan"
  value       = aws_backup_plan.comprehensive.id
}

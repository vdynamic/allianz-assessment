This module creates a comprehensive AWS Backup solution with the following features:

### Features
- **Cross-Region Backup**: Automatic replication to secondary region
- **Cross-Account Backup**: Copy backups to different AWS account for additional security
- **WORM Protection**: Vault Lock implementation to prevent accidental or malicious deletion
- **Tag-Based Selection**: Automatically backup resources with specific tags
- **Multiple Retention Policies**: Different retention periods for different backup types
- **Monitoring and Alerting**: CloudWatch dashboards and alarms for backup monitoring

### Usage

```hcl
module "aws_backup" {
  source = "./modules/aws-backup"

  providers = {
    aws.cross_region = aws.cross_region
  }

  backup_vault_name           = "my-backup-vault"
  backup_plan_name           = "my-backup-plan"
  cross_account_destination  = "123456789012"
  
  tags = {
    Environment = "production"
    Owner      = "admin@company.com"
  }
}
```

### Resource Selection
Resources are automatically selected for backup if they have the following tags:
- `ToBackup = "true"`
- `Owner = "*@eulerhermes.com"`

### Supported Resources
- Amazon RDS (databases and clusters)
- Amazon DynamoDB tables
- Amazon S3 buckets
- Amazon EBS volumes
- Amazon EFS file systems

### Security Features
- Encryption at rest using KMS
- IAM roles with least privilege access
- Vault lock for WORM compliance
- Cross-region and cross-account redundancy

### Monitoring
- CloudWatch dashboard for backup metrics
- CloudWatch alarms for backup failures
- SNS notifications for alerts

### Compliance
- Configurable retention periods
- Vault lock for regulatory compliance
- Audit logging through CloudTrail
- Cross-account backup for disaster recovery
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Primary region provider
provider "aws" {
  region = "eu-west-1"
  
  default_tags {
    tags = {
      Environment = "production"
      Project     = "allianz-trade-backup"
      ManagedBy   = "terraform"
      CostCenter  = "security"
    }
  }
}

# Cross-region provider for backup replication
provider "aws" {
  alias  = "cross_region"
  region = "eu-central-1"
  
  default_tags {
    tags = {
      Environment = "production"
      Project     = "allianz-trade-backup"
      ManagedBy   = "terraform"
      CostCenter  = "security"
    }
  }
}
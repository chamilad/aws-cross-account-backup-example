terraform {
  required_version = "~> 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.55"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

# Set the regional settings, especially for DynamoDB cross-account backup features to work
resource "aws_backup_region_settings" "settings" {
  resource_type_opt_in_preference = {
    "Aurora"          = false
    "DocumentDB"      = false
    "DynamoDB"        = true
    "EBS"             = true
    "EC2"             = true
    "EFS"             = true
    "FSx"             = false
    "Neptune"         = false
    "RDS"             = true
    "Storage Gateway" = false
    "VirtualMachine"  = false
    "Redshift"        = false
    "Timestream"      = false
    "CloudFormation"  = false
    "S3"              = false
  }

  # Enable advanced features for dynamodb backups
  resource_type_management_preference = {
    "DynamoDB" = true
    "EFS"      = true
  }
}

# central backup vault encryption
resource "aws_kms_key" "central_vault" {
  description         = "Encrypt production data"
  policy              = data.aws_iam_policy_document.central_vault_key_policy.json
  enable_key_rotation = true
}

resource "aws_kms_alias" "central_vault" {
  name          = "alias/backup_vault_central"
  target_key_id = aws_kms_key.central_vault.id
}

resource "aws_backup_vault" "central" {
  name        = "prod"
  kms_key_arn = aws_kms_key.central_vault.arn
}

# Set the vault policy so that other accounts are able to copy snapshots into this vault
resource "aws_backup_vault_policy" "central" {
  backup_vault_name = aws_backup_vault.central.name

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Allow all accounts under the Organisation to copy into central backup account",
            "Effect": "Allow",
            "Action": "backup:CopyIntoBackupVault",
            "Resource": "*",
            "Principal": "*",
            "Condition": {
                "StringEquals": {
                    "aws:PrincipalOrgID": [
                        "${data.aws_organizations_organization.current.id}"
                    ]
                }
            }
        }
    ]
}
POLICY
}

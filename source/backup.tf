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

################################################################################
# Backup vault
################################################################################

# source backup vault encryption
resource "aws_kms_key" "source_vault" {
  description         = "Encrypt production data"
  policy              = data.aws_iam_policy_document.source_vault_key_policy.json
  enable_key_rotation = true
}

resource "aws_kms_alias" "source_vault" {
  name          = "alias/backup_vault_source"
  target_key_id = aws_kms_key.source_vault.id
}

resource "aws_backup_vault" "source" {
  name        = "prod"
  kms_key_arn = aws_kms_key.source_vault.arn
}

resource "aws_backup_vault_policy" "source" {
  backup_vault_name = aws_backup_vault.source.name

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

################################################################################
# Backup plan for DynamoDB
################################################################################

# backup job role for DynamoDB, is assumed by AWS Backup when performing a snapshot operation
resource "aws_iam_role" "backup_dynamodb" {
  name = "backup_dynamodb"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "backup.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup",
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  ]
}

# The actual backup plan for DynamoDB, only consists of a single rule for now.
resource "aws_backup_plan" "dynamodb" {
  name = "dynamodb"

  rule {
    rule_name         = "dynamodb_hourly"
    schedule          = "cron(0 5/1 ? * * *)" # 0th minute of each hour, starting from 0500UTC
    target_vault_name = aws_backup_vault.source.name
    start_window      = 480   # start within 8 hours
    completion_window = 10080 # complete within 7 days

    lifecycle {
      delete_after = 30
    }

    copy_action {
      destination_vault_arn = var.destination_vault_arn

      lifecycle {
        delete_after = 30
      }
    }
  }
}

resource "aws_backup_selection" "dynamodb_tracking" {
  iam_role_arn = aws_iam_role.backup_dynamodb.arn
  name         = "dynamodb-tracking"
  plan_id      = aws_backup_plan.dynamodb.id

  resources = [
    aws_dynamodb_table.tracking.arn
  ]
}

################################################################################
# Backup plan for RDS
################################################################################

# backup job role for rds, same as the role for DynamoDB above
resource "aws_iam_role" "backup_rds" {
  name = "backup_rds"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "backup.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup",
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  ]
}

resource "aws_backup_plan" "rds" {
  name = "rds"

  rule {
    rule_name         = "rds_hourly"
    schedule          = "cron(0 5/1 ? * * *)" # 0th minute of each hour, starting from 0500UTC
    target_vault_name = aws_backup_vault.source.name
    start_window      = 480   # start within 8 hours
    completion_window = 10080 # complete within 7 days

    lifecycle {
      delete_after = 30
    }

    copy_action {
      destination_vault_arn = var.destination_vault_arn

      lifecycle {
        delete_after = 30
      }
    }
  }
}

resource "aws_backup_selection" "rds_mydb" {
  iam_role_arn = aws_iam_role.backup_rds.arn
  name         = "rds-mydb"
  plan_id      = aws_backup_plan.rds.id

  resources = [
    aws_db_instance.mydb.arn
  ]
}

data "aws_caller_identity" "current" {}

data "aws_organizations_organization" "current" {}

# The key policy for the CMK that encrypts the databases.
data "aws_iam_policy_document" "critical_data_key_policy" {
  statement {
    sid    = "Enable IAM policy usage for key management"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions = [
      "kms:*"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid    = "Allow source account to take backups of resources that don't support independent encryption"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.backup_rds.arn,
      ]
    }

    actions = [
      "kms:GenerateDataKey",
      "kms:DescribeKey",
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:CreateGrant",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "Allow destination account AWS Backup to copy snapshots made from this key, for resources that don't support independent encryption"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        var.destination_backup_service_linked_role_arn,
      ]
    }

    actions = [
      "kms:GenerateDataKey",
      "kms:DescribeKey",
      "kms:Decrypt",
      "kms:CreateGrant",
    ]

    resources = ["*"]
  }
}

# key policy for the vault encryption key
data "aws_iam_policy_document" "source_vault_key_policy" {
  statement {
    sid    = "Enable IAM policy usage for key management"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions = [
      "kms:*"
    ]

    resources = [
      "*"
    ]
  }
}

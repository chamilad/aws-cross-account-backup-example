data "aws_caller_identity" "current" {}

data "aws_organizations_organization" "current" {}

# Other than providing IAM access to manage key permissions, there is nothing else to be done here.
data "aws_iam_policy_document" "central_vault_key_policy" {
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

data "aws_iam_role" "backup_service_linked_role" {
  name = "AWSServiceRoleForBackup"
}

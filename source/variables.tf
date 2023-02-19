variable "destination_vault_arn" {
  type        = string
  description = "the ARN of the central backup vault to perform cross-account backups"
}

variable "destination_backup_service_linked_role_arn" {
  type        = string
  description = "the ARN of the AWS Backup Service-linked role in the destination account"
}

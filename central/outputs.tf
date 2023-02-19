output "vault_arn" {
  value = aws_backup_vault.central.arn
}

output "backup_service_linked_role_arn" {
  value = data.aws_iam_role.backup_service_linked_role.arn
}

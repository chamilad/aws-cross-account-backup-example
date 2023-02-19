# AWS Backup with Cross-Account Backups Example

This is an example setup to demonstrate AWS Backup cross-account backup
capabiliites. For more details, refer to [the associated blog
post](https://chamila.dev/blog/2023-02-17_aws-backup-implementing-a-simple-cross-account-backup-strategy/).

## Deployment

> NOTE: This code is not optimised or secured for production by any means. Do
> NOT use it as is.

The Terraform code is organised into two root modules. [`central`](./central)
is supposed to be run on the central backup account, while [`source`](./source)
is to be run on the account that represents the account with the actual
database instances.

> You will need an IAM role with permissions to create and modify all the
> resources addressed in these modules, `AWSAdministrator` being the safest
> bet. All resources are created in the `ap-southeast-2` region.

1. Get AWS credentials (temporary or permanent) for the account that is
   supposed to be the central backup account. Prep a Bash session with the
   credentials.
1. Navigate to the `central` directory and run `terraform apply`. After
   successful application, two outputs, `backup_service_linked_role_arn` and
   `vault_arn` will be provided.
1. Get AWS credentials (temporary or permanent) for the business data account.
   Prep a separate Bash session with those credentials.
1. Navigate to the `source` directory and run `terraform apply`. Use the above
   output values for the variables (either as a Terraform `tfvars` file or
   command line inputs).
1. Check back in a couple of hours for the results!

> The module structure is intentionally kept simple. If you're adapting this
> into your code, change the provider configuration as needed.

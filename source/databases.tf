resource "aws_kms_key" "critical_data" {
  description         = "Encrypt production critical data"
  policy              = data.aws_iam_policy_document.critical_data_key_policy.json
  enable_key_rotation = true
}

resource "aws_kms_alias" "critical_data" {
  name          = "alias/critical_data"
  target_key_id = aws_kms_key.critical_data.id
}

# not really worried about the structure for the databases here
resource "aws_dynamodb_table" "tracking" {
  name         = "tracking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "cust_id"
  range_key    = "location"

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.critical_data.arn
  }

  attribute {
    name = "cust_id"
    type = "S"
  }

  attribute {
    name = "location"
    type = "S"
  }
}

resource "aws_db_instance" "mydb" {
  allocated_storage    = 10
  db_name              = "mydb"
  identifier           = "mydb"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true

  kms_key_id        = aws_kms_key.critical_data.arn
  storage_encrypted = true
}

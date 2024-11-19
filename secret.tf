

resource "aws_secretsmanager_secret" "rds_cred_4" {
  name        = "rds-cred-4"
  description = "RDS cred for fitness app db"

}

resource "aws_secretsmanager_secret_version" "rds_cred_version" {
  secret_id = aws_secretsmanager_secret.rds_cred_4.id
  secret_string = jsonencode({
    username = "money43"
    password = "money12348"
  })
}
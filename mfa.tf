#MFA enable else you wont be able to work
resource "aws_iam_policy" "mfa_policy" {
  name        = "mfa_policy"
  description = "MFA for all users in the group"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringEqualsIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })

}

#MFA Device
resource "aws_iam_virtual_mfa_device" "mfa_fitapp" {
  virtual_mfa_device_name = "exampleuser-fitness-app"

}
#password
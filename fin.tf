# finance group
resource "aws_iam_group" "finance_group" {
  name = "developers"

}

# create IAM User


resource "aws_iam_user" "finance_user" {
  name = "finance"

}


# adding user to the group
resource "aws_iam_user_group_membership" "finance_group_member" {
  user = aws_iam_user.finance_user.name
  groups = [
    aws_iam_group.finance_group.name,
  ]


}

#policy
resource "aws_iam_policy" "finance_policy" {
  name        = "finance_policy"
  description = "Giving Cost Managementaccess to finance team"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ce:*",
          "budgets:*",
          "aws-portal:ViewBilling",
          "aws-portal:ViewPaymentHistory"
        ]
        Resource = "*"
      }
    ]
  })

}

#policy attached
resource "aws_iam_policy_attachment" "finance_attach" {
  name       = "finance-attach"
  groups     = [aws_iam_group.finance_group.name]
  policy_arn = aws_iam_policy.finance_policy.arn

}
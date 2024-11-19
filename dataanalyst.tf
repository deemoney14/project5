# 3 Data Analyst
resource "aws_iam_group" "data_analyst_group" {
  name = "data_analyst"

}

# create IAM User
locals {
  data_analyst = {
    data_analyst1 = "data_analyst1",
    data_analyst2 = "data_analyst2",
    data_analyst3 = "data_analyst3"
  }
}

resource "aws_iam_user" "data_analyst" {
  for_each = local.data_analyst
  name     = each.value

  tags = {
    Name = "data_analyst"
  }

}
# adding user to the group
resource "aws_iam_user_group_membership" "data_analyst_user_group" {
  user     = aws_iam_user.data_analyst[each.key].name
  for_each = aws_iam_user.data_analyst
  groups = [
    aws_iam_group.data_analyst_group.name,
  ]

}

resource "aws_iam_policy" "data_analyst_policy" {
  name        = "data_analyst_policy"
  description = "Giving Read-only s3&rds to the data analyst"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"

        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:Describe*",
          "rds:ListTagsForResource"

        ]
        Resource = "*"
      }
    ]
  })

}

# policy attachment
resource "aws_iam_policy_attachment" "data_policy_attach" {
  name       = "data_analyst_policy"
  groups     = [aws_iam_group.data_analyst_group.name]
  policy_arn = aws_iam_policy.data_analyst_policy.arn

}
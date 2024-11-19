# 4 Developers(EC2 and S3 access)
resource "aws_iam_group" "developers_group" {
  name = "dev"



}

# create IAM User
locals {
  developers = {
    developer1 = "developer1",
    developer2 = "developer2",
    developer3 = "developer3",
    developer4 = "developer4"
  }
}

resource "aws_iam_user" "developers" {
  for_each = local.developers
  name     = each.value

  tags = {
    Name = "developers"
  }

}
# adding user to the group
resource "aws_iam_user_group_membership" "user_group" {
  user     = aws_iam_user.developers[each.key].name
  for_each = aws_iam_user.developers
  groups = [
    aws_iam_group.developers_group.name,
  ]


}

#Policy
resource "aws_iam_policy" "dev_policy" {
  name        = "dev_policy"
  description = "Giving access to the develop group"


  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = "*"

      },

      {
        Effect = "Allow"
        Action = [
          "ec2:*"
        ]
        Resource = "*"
      },

      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}


# policy attachment
resource "aws_iam_policy_attachment" "dev_policy_attach" {
  name       = "dev_policy_attach"
  groups     = [aws_iam_group.developers_group.name]
  policy_arn = aws_iam_policy.dev_policy.arn

}
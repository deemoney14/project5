# 2 Operators
resource "aws_iam_group" "operation_group" {
  name = "operation"



}

# create IAM User
locals {
  operation = {
    operation1 = "operation1",
    operation2 = "operation2"
  }
}

resource "aws_iam_user" "operation" {
  for_each = local.operation
  name     = each.value

  tags = {
    Name = "operation"
  }

}
# adding user to the group
resource "aws_iam_user_group_membership" "operate_user_group" {
  user     = aws_iam_user.operation[each.key].name
  for_each = aws_iam_user.operation
  groups = [
    aws_iam_group.operation_group.name,
  ]


}

#ec2 access
resource "aws_iam_group_policy_attachment" "operations_admin_access1" {
  group      = aws_iam_group.operation_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}
#cloudwatch access
resource "aws_iam_group_policy_attachment" "operations_admin_access2" {
  group      = aws_iam_group.operation_group.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}
# system manager access
resource "aws_iam_group_policy_attachment" "operations_admin_access3" {
  group      = aws_iam_group.operation_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}
# rds access
resource "aws_iam_group_policy_attachment" "operations_admin_access4" {
  group      = aws_iam_group.operation_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}
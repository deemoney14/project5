#IAM ROLE for the cloud watch
resource "aws_iam_role" "s3_cloudwatch_role" {
  name = "EC2_s3_cloudwatch_policy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    Name = "s3_cloudwatch_role"
  }
  #I AM POLICY 
}
resource "aws_iam_policy" "s3_cloudwatch_policy" {
  name        = "s3_cloudwatch_ec2"
  description = "s3 and cloudwatch permission for ec2 instance"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = "*"
      }
    ]
  })


}
# iam role and policy attachment
resource "aws_iam_role_policy_attachment" "attach_cw" {
  role       = aws_iam_role.s3_cloudwatch_role.name
  policy_arn = aws_iam_policy.s3_cloudwatch_policy.arn

}

#instance profile
resource "aws_iam_instance_profile" "cloudwatch_instance_profile" {
  name = "ec2_s3_cloudwatchprofile"
  role = aws_iam_role.s3_cloudwatch_role.name

}
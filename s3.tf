#s3 bucket
resource "aws_s3_bucket" "s3_fitapp" {
  bucket = "my-sa-fitapp-bucket-kl"

  tags = {
    Name = "s3_fitapp"
  }

}

resource "aws_s3_bucket_public_access_block" "fitapp_public" {
  bucket                  = aws_s3_bucket.s3_fitapp.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

}


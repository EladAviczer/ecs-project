resource "aws_s3_bucket" "bucket" {
  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket" "tf_s3_bucket" {
  bucket = "nodejs-bkt-arav"

  tags = {
    Name        = "Nodejs terraform bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_object" "tf_s3_object" {
  bucket = aws_s3_bucket.tf_s3_bucket.bucket

  for_each = fileset("../app/public/images", "**")
  key      = "images/${each.key}"
  source   = "../app/public/images/${each.key}"
}
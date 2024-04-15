resource "aws_s3_bucket" "root" {
  bucket        = "${local.prefix}-dbx-rootbucket"
  force_destroy = true
  tags = merge(local.tags, {
    Name = "${local.prefix}-dbx-rootbucket"
  })
}

resource "aws_s3_bucket_ownership_controls" "root" {
  bucket = aws_s3_bucket.root.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "root" {
  depends_on = [aws_s3_bucket_ownership_controls.root]

  bucket = aws_s3_bucket.root.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "root" {
  bucket = aws_s3_bucket.root.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "root" {
  bucket                  = aws_s3_bucket.root.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.root]
}

# AWS IAM Policy that only gives the Databricks AWS Account access to the S3 bucket
data "databricks_aws_bucket_policy" "this" {
  bucket = aws_s3_bucket.root.bucket
}

resource "aws_s3_bucket_policy" "root_bucket_policy" {
  bucket     = aws_s3_bucket.root.id
  policy     = data.databricks_aws_bucket_policy.this.json
  depends_on = [aws_s3_bucket_public_access_block.root]
}

resource "aws_s3_bucket_versioning" "root_bucket_versioning" {
  bucket = aws_s3_bucket.root.id
  versioning_configuration {
    status = "Disabled"
  }
}
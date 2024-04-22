resource "aws_s3_bucket" "external" {
  bucket        = "${local.prefix}-dbx-external"
  force_destroy = true
  tags = merge(local.tags, {
    Name = "${local.prefix}-external"
  })
}

resource "aws_s3_bucket_ownership_controls" "external" {
  bucket = aws_s3_bucket.external.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_acl" "external" {
  depends_on = [aws_s3_bucket_ownership_controls.external]

  bucket = aws_s3_bucket.external.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "external_versioning" {
  bucket = aws_s3_bucket.external.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "external" {
  bucket                  = aws_s3_bucket.external.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.external]
}

resource "aws_s3_bucket_versioning" "external" {
  bucket = aws_s3_bucket.external.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "external" {
  bucket = aws_s3_bucket.external.id

  rule {
    id     = "log"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    expiration {
      days = 10000
    }

  }
}

data "aws_iam_policy_document" "passrole_for_uc" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = [databricks_storage_credential.external.aws_iam_role[0].unity_catalog_iam_arn]
      type        = "AWS"
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [databricks_storage_credential.external.aws_iam_role[0].external_id]
    }
  }
  statement {
    sid     = "ExplicitSelfRoleAssumption"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-uc-access"]
    }
  }
}

resource "aws_iam_policy" "external_data_access" {
  // Terraform's "jsonencode" function converts a
  // Terraform expression's result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${aws_s3_bucket.external.id}-access"
    Statement = [
      {
        "Action" : [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        "Resource" : [
          aws_s3_bucket.external.arn,
          "${aws_s3_bucket.external.arn}/*",
          "arn:aws:s3:::${local.prefix}-dbx-rootbucket",
          "arn:aws:s3:::${local.prefix}-dbx-rootbucket/*"
        ],
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "sts:AssumeRole"
        ],
        "Resource" : [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-uc-access"
        ],
        "Effect" : "Allow"
      },
    ]
  })
  tags = merge(local.tags, {
    Name = "${local.prefix}-unity-catalog external access IAM policy"
  })
}

resource "aws_iam_role" "external_data_access" {
  name                = "${local.prefix}-dbx-uc-access"
  assume_role_policy  = data.aws_iam_policy_document.passrole_for_uc.json
  managed_policy_arns = [aws_iam_policy.external_data_access.arn]
  tags = merge(local.tags, {
    Name = "${local.prefix}-dbx-unity-catalog external access IAM role"
  })
}
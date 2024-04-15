## Encrypt the workspace's root S3 bucket and clusters' EBS volumes with a CMK. ##

data "aws_iam_policy_document" "databricks_workspace_storage_cmk" {
  version = "2012-10-17"
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
  statement {
    sid    = "Allow Databricks to use KMS key for DBFS"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::414351767826:root"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "Allow Databricks to use KMS key for DBFS (Grants)"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::414351767826:root"]
    }
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
  statement {
    sid    = "Allow Databricks to use KMS key for EBS"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cross_account_role.arn]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "kms:ViaService"
      values   = ["ec2.*.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "workspace_storage_customer_managed_key" {
  policy = data.aws_iam_policy_document.databricks_workspace_storage_cmk.json
  description = "Encrypt the workspace's root S3 bucket and clusters' EBS volumes with a CMK."
  tags = local.tags
}

resource "aws_kms_alias" "workspace_storage_customer_managed_key_alias" {
  name          = "alias/workspace_storage-customer-managed-key-alias"
  target_key_id = aws_kms_key.workspace_storage_customer_managed_key.key_id
}

resource "databricks_mws_customer_managed_keys" "workspace_storage" {
  provider = databricks.mws
  account_id = var.databricks_account_id
  aws_key_info {
    key_arn   = aws_kms_key.workspace_storage_customer_managed_key.arn
    key_alias = aws_kms_alias.workspace_storage_customer_managed_key_alias.name
  }
  use_cases = ["STORAGE"]
}
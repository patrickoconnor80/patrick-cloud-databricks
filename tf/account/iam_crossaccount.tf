data "databricks_aws_assume_role_policy" "this" {
  external_id = var.databricks_account_id
}

resource "aws_iam_role" "cross_account_role" {
  name               = "${local.prefix}-dbx-crossaccount"
  assume_role_policy = data.databricks_aws_assume_role_policy.this.json
  tags               = local.tags
}

data "databricks_aws_crossaccount_policy" "this" {
  policy_type = "customer" # Customer managed VPC vs. Databricks managed VPC
}

resource "aws_iam_role_policy" "this" {
  name   = "${local.prefix}-dbx-policy"
  role   = aws_iam_role.cross_account_role.id
  policy = data.databricks_aws_crossaccount_policy.this.json
}
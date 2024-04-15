resource "aws_secretsmanager_secret" "dbx_sql_endpoint" {
  name = "DATABRICKS_SQL_ENDPOINT"
  policy = data.aws_iam_policy_document.secrets_policy.json
  kms_key_id = aws_kms_key.secrets.key_id
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "dbx_sql_endpoint" {
  secret_id     = aws_secretsmanager_secret.dbx_sql_endpoint.id
  secret_string = databricks_sql_endpoint.this.odbc_params[0].path
}


## IAM ACCESS POLICY ##

data "aws_iam_policy_document" "secrets_policy" {

  # statement {
  #   sid    = "GetSecret"
  #   effect = "Allow"
  #   principals {
  #     type        = "AWS"
  #     identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-eks-external-secrets-sa-role"]
  #   }
  #   actions = ["secretsmanager:GetSecretValue"]
  #   resources = ["arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:DATABRICKS_SQL_ENDPOINT*"]
  # }

  statement {
    sid    = "AdminAccessToSecret"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = [
      "secretsmanager:*"
    ]
    resources = ["arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:DATABRICKS_SQL_ENDPOINT*"]
  }
}


## KMS ##

resource "aws_kms_key" "secrets" {
  description             = "CMK for the Databricks Workspace Secrets"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  is_enabled              = true
  policy                  = data.aws_iam_policy_document.secrets_kms_policy.json

  tags = local.tags
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${local.prefix}-databricks-workspace-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

data "aws_iam_policy_document" "secrets_kms_policy" {
  
  # statement {
  #   sid    = "DecryptSecretsKMSKey"
  #   effect = "Allow"
  #   principals {
  #     type        = "AWS"
  #     identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-eks-external-secrets-sa-role"]
  #   }
  #   actions = [
  #     "kms:Decrypt",
  #     "kms:GenerateDataKey"
  #   ]
  #   resources = ["*"]
  # }
    
  statement {
    sid    = "AdminAccessToKMS"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = [
      "kms:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "secrets_kms_access" {
  name        = "${local.prefix}-dataricks-workspace-secrets-kms-access"
  path        = "/"
  description = "This Policy gives KMS access to Dataricks Workspace Secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "DecryptKMSkeyforSecrets"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Effect   = "Allow"
        Resource = aws_kms_key.secrets.arn
      }
    ]
  })

  tags = local.tags
}
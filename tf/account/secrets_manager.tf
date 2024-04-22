
resource "aws_secretsmanager_secret" "dbx_token" {
  name       = "DATABRICKS_TOKEN_"
  policy     = data.aws_iam_policy_document.secrets_policy.json
  kms_key_id = aws_kms_key.secrets.key_id
  tags       = local.tags
}

resource "aws_secretsmanager_secret_version" "dbx_token" {
  secret_id     = aws_secretsmanager_secret.dbx_token.id
  secret_string = databricks_mws_workspaces.this.token[0].token_value
}


resource "aws_secretsmanager_secret" "dbx_host" {
  name       = "DATABRICKS_HOST"
  policy     = data.aws_iam_policy_document.secrets_policy.json
  kms_key_id = aws_kms_key.secrets.key_id
  tags       = local.tags
}

resource "aws_secretsmanager_secret_version" "dbx_host" {
  secret_id     = aws_secretsmanager_secret.dbx_host.id
  secret_string = split("/", databricks_mws_workspaces.this.workspace_url)[2] # Remove https://
}


## IAM ACCESS POLICY ##

data "aws_iam_policy_document" "secrets_policy" {

  statement {
    sid    = "GetSecret"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-eks-dbt-external-secrets-sa-role"]
    }
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:DATABRICKS_TOKEN_*",
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:DATABRICKS_HOST*"
    ]
  }

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
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:DATABRICKS_TOKEN_*",
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:DATABRICKS_HOST*"
    ]
  }
}


## KMS ##

resource "aws_kms_key" "secrets" {
  description             = "CMK for the Databricks Account Secrets"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  is_enabled              = true
  policy                  = data.aws_iam_policy_document.secrets_kms_policy.json

  tags = local.tags
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${local.prefix}-databricks-account-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

data "aws_iam_policy_document" "secrets_kms_policy" {

  statement {
    sid    = "DecryptSecretsKMSKey"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-eks-dbt-external-secrets-sa-role"]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = ["*"]
  }

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
  name        = "${local.prefix}-dataricks-account-secrets-kms-access"
  path        = "/"
  description = "This Policy gives KMS access to Dataricks Account Secrets"

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
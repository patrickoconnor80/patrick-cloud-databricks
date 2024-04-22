// register credentials
resource "databricks_mws_credentials" "this" {
  provider         = databricks.mws
  role_arn         = aws_iam_role.cross_account_role.arn
  credentials_name = "${local.prefix}-creds"
  depends_on       = [aws_iam_role_policy.this]
}

// register root bucket
resource "databricks_mws_storage_configurations" "this" {
  provider                   = databricks.mws
  account_id                 = var.databricks_account_id
  storage_configuration_name = "${local.prefix}-dbx-storage"
  bucket_name                = aws_s3_bucket.root.id
}

// register VPC
resource "databricks_mws_networks" "this" {
  provider           = databricks.mws
  account_id         = var.databricks_account_id
  network_name       = "${local.prefix}-dbx-network"
  vpc_id             = data.aws_vpc.this.id
  subnet_ids         = local.private_subnet_ids
  security_group_ids = [data.aws_security_group.dbx.id]
  vpc_endpoints {
    dataplane_relay = [databricks_mws_vpc_endpoint.relay.vpc_endpoint_id]
    rest_api        = [databricks_mws_vpc_endpoint.backend_rest.vpc_endpoint_id]
  }
  depends_on = [aws_vpc_endpoint.backend_rest, aws_vpc_endpoint.relay]
}

// create workspace in given VPC with DBFS on root bucket
resource "databricks_mws_workspaces" "this" {
  provider       = databricks.mws
  account_id     = var.databricks_account_id
  workspace_name = local.prefix
  aws_region     = data.aws_region.current.name

  credentials_id             = databricks_mws_credentials.this.credentials_id
  storage_configuration_id   = databricks_mws_storage_configurations.this.storage_configuration_id
  network_id                 = databricks_mws_networks.this.network_id
  private_access_settings_id = databricks_mws_private_access_settings.this.private_access_settings_id

  token {}

  # cmk
  storage_customer_managed_key_id          = databricks_mws_customer_managed_keys.workspace_storage.customer_managed_key_id
  managed_services_customer_managed_key_id = databricks_mws_customer_managed_keys.managed_services.customer_managed_key_id
}


## SECURITY GROUP RULES ##

resource "aws_security_group_rule" "dbx_ingress_self" {
  type              = "ingress"
  description       = "Allow all internal TCP and UDP traffic from the Databricks cluster"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  self              = true
  security_group_id = data.aws_security_group.dbx.id
}

resource "aws_security_group_rule" "dbx_egress_self" {
  type              = "egress"
  description       = "Allow all internal TCP and UDP traffic to the Databricks cluster"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = data.aws_security_group.dbx.id
}

resource "aws_security_group_rule" "dbx_egress_https" {
  type              = "egress"
  description       = "Allow outbound traffic on port 443"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.dbx.id
}

resource "aws_security_group_rule" "dbx_egress_http" {
  type              = "egress"
  description       = "Allow outbound traffic on port 80"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.dbx.id
}

resource "aws_security_group_rule" "dbx_egress_metastore" {
  type              = "egress"
  description       = "Allow outbound traffic on port 3306"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.dbx.id
}

resource "aws_security_group_rule" "dbx_egress_privatelink" {
  type              = "egress"
  description       = "Allow outbound traffic on port 6666"
  from_port         = 6666
  to_port           = 6666
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.dbx.id
}
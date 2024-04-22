resource "aws_vpc_endpoint" "backend_rest" {
  vpc_id              = data.aws_vpc.this.id
  service_name        = local.databricks_rest_api_vpce_service
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [data.aws_security_group.dbx_dataplane_vpce.id]
  subnet_ids          = local.dbx_dataplane_vpce_subnet_ids
  private_dns_enabled = true
  tags = merge(
    {
      Name = "${local.prefix}-dbx-vpce-backend-rest-interface-endpoint"
    },
    local.tags
  )
}

resource "aws_vpc_endpoint" "relay" {
  vpc_id              = data.aws_vpc.this.id
  service_name        = local.databricks_conn_relay_vpce_service
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [data.aws_security_group.dbx_dataplane_vpce.id]
  subnet_ids          = local.dbx_dataplane_vpce_subnet_ids
  private_dns_enabled = true
  tags = merge(
    {
      Name = "${local.prefix}-dbx-vpce-relay-interface-endpoint"
    },
    local.tags
  )
}

resource "databricks_mws_vpc_endpoint" "backend_rest" {
  provider            = databricks.mws
  account_id          = var.databricks_account_id
  aws_vpc_endpoint_id = aws_vpc_endpoint.backend_rest.id
  vpc_endpoint_name   = "${local.prefix}-dbx-vpce-backend"
  region              = data.aws_region.current.name
  depends_on          = [aws_vpc_endpoint.backend_rest]
}

resource "databricks_mws_vpc_endpoint" "relay" {
  provider            = databricks.mws
  account_id          = var.databricks_account_id
  aws_vpc_endpoint_id = aws_vpc_endpoint.relay.id
  vpc_endpoint_name   = "${local.prefix}-dbx-vpce-relay"
  region              = data.aws_region.current.name
  depends_on          = [aws_vpc_endpoint.relay]
}

resource "databricks_mws_private_access_settings" "this" {
  provider                     = databricks.mws
  account_id                   = var.databricks_account_id
  private_access_settings_name = "Private Access Settings for ${local.prefix}"
  region                       = data.aws_region.current.name
  public_access_enabled        = true
}


## SECURITY GROUP RULES ##

resource "aws_security_group_rule" "dbx_dataplane_vpce_ingress_https" {
  type                     = "ingress"
  description              = "Allow inbound traffic from DBX EC2 resources on port 443"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.dbx.id
  security_group_id        = data.aws_security_group.dbx_dataplane_vpce.id
}

resource "aws_security_group_rule" "dbx_dataplane_vpce_ingress_fips" {
  type                     = "ingress"
  description              = "Allow inbound traffic from DBX EC2 resources on port 2443"
  from_port                = 2443
  to_port                  = 2443
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.dbx.id
  security_group_id        = data.aws_security_group.dbx_dataplane_vpce.id
}

resource "aws_security_group_rule" "dbx_dataplane_vpce_ingress_privatelink" {
  type                     = "ingress"
  description              = "Allow inbound traffic from DBX EC2 resources on port 6666"
  from_port                = 6666
  to_port                  = 6666
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.dbx.id
  security_group_id        = data.aws_security_group.dbx_dataplane_vpce.id
}

resource "aws_security_group_rule" "dbx_dataplane_vpce_egress_https" {
  type              = "egress"
  description       = "Allow all outgoing traffic on port 443"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.dbx_dataplane_vpce.id
}

resource "aws_security_group_rule" "dbx_dataplane_vpce_egress_fips" {
  type                     = "egress"
  description              = "Allow outbound traffic to DBX EC2 resources on port 2443"
  from_port                = 2443
  to_port                  = 2443
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.dbx.id
  security_group_id        = data.aws_security_group.dbx_dataplane_vpce.id
}

resource "aws_security_group_rule" "dbx_dataplane_vpce_egress_privatelink" {
  type                     = "egress"
  description              = "Allow outbound traffic to DBX EC2 resources on port 6666"
  from_port                = 6666
  to_port                  = 6666
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.dbx.id
  security_group_id        = data.aws_security_group.dbx_dataplane_vpce.id
}

resource "aws_security_group_rule" "dbx_dataplane_vpce_ingress_snowplow" {
  type                     = "ingress"
  description              = "Allow inbound traffic from the Snowplow Loader EC2 on port 443"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.snowplow_db_loader.id
  security_group_id        = data.aws_security_group.dbx_dataplane_vpce.id
}

resource "aws_security_group_rule" "local" {
  type              = "ingress"
  description       = "Allow inbound traffic from my local network"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["${data.http.my_ip.body}/32"]
  security_group_id = data.aws_security_group.dbx_dataplane_vpce.id
}

resource "aws_security_group_rule" "dbx_dataplane_vpce_ingress_kubernetes" {
  type                     = "ingress"
  description              = "Allow inbound traffic from the Kubernetes Cluster on port 443"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.kubernetes.id
  security_group_id        = data.aws_security_group.dbx_dataplane_vpce.id
}
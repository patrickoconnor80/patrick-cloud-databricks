locals {
    prefix = "patrick-cloud-${var.env}"
    private_subnet_ids = [for subnet in data.aws_subnet.private : subnet.id]
    dbx_dataplane_vpce_subnet_ids = [for subnet in data.aws_subnet.dbx_dataplane_vpce : subnet.id]
    
    databricks_metastore_admins = ["patrickoconnor8014@gmail.com"]

    # VPC Endpoints via https://docs.databricks.com/en/resources/supported-regions.html#privatelink
    databricks_rest_api_vpce_service = "com.amazonaws.vpce.us-east-1.vpce-svc-09143d1e626de2f04" 
    databricks_conn_relay_vpce_service = "com.amazonaws.vpce.us-east-1.vpce-svc-00018a8c3ff62ffdf"
    
    tags = {
        env        = var.env
        project       = "patrick-cloud"
        deployment = "terraform"
        repo = "https://github.com/patrickoconnor80/patrick-cloud-databricks/tree/main/tf/mws"
    }
}
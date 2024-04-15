# data "http" "my" {
#   url = "https://ifconfig.me"
# }

# resource "databricks_workspace_conf" "this" {
#   custom_config = {
#     "enableIpAccessLists" : true
#   }
# }

# resource "databricks_ip_access_list" "only_me" {
#   label        = "only ${data.http.my.body} is allowed to access workspace"
#   list_type    = "ALLOW"
#   ip_addresses = ["${data.http.my.body}/32"]
#   depends_on   = [databricks_workspace_conf.this]
# }

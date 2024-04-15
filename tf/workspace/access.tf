resource "databricks_group" "read_only" {
  display_name = "Read Only"
}

resource "databricks_secret_acl" "read_only" {
  principal  = databricks_group.read_only.display_name
  scope      = databricks_secret_scope.this.name
  permission = "READ"
}

resource "databricks_user" "admin" {
  user_name    = "patrickoconnor8014@gmail.com"
  display_name = "Patrick OConnor"
}

resource "databricks_group_member" "read_only" {
  group_id  = databricks_group.read_only.id
  member_id = databricks_user.admin.id
}
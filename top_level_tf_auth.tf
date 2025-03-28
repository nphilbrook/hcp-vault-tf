resource "vault_jwt_auth_backend" "jwt_hcp_tf_top_level" {
  for_each           = vault_namespace.top_level_namespaces
  namespace          = each.value.path
  description        = "JWT auth backend for HCP Terraform"
  path               = "jwt"
  oidc_discovery_url = "https://app.terraform.io"
  bound_issuer       = "https://app.terraform.io"
}

# This role will be used by the vault-terraform-admin workspace to manage the `admin/live` namespace, tested in `admin/testing` namespace
# Ref workspace variable setup: https://github.com/nphilbrook/hcp-tf-control/TBW
resource "vault_policy" "hcp_tf_top_level" {
  for_each  = vault_namespace.top_level_namespaces
  namespace = each.value.path
  name      = "hcp-tf-toplevel"
  # ref top_level_tf_policy.tf
  policy = data.vault_policy_document.hcp_tf_top_level.hcl
}

resource "vault_jwt_auth_backend_role" "hcp_tf_top_level" {
  for_each  = vault_namespace.top_level_namespaces
  namespace = each.value.path

  backend        = vault_jwt_auth_backend.jwt_hcp_tf_top_level[each.key].path
  role_name      = "hcp-tf-top-level"
  token_policies = ["default", vault_policy.hcp_tf_top_level[each.key].name]

  bound_audiences = ["vault.workload.identity"]
  bound_claims = {
    sub = "organization:philbrook:project:SB Vault Lab:workspace:vault-admin-terraform-${each.value.path}:run_phase:*"
  }
  bound_claims_type = "glob"
  user_claim        = "terraform_project_id"
  role_type         = "jwt"
}

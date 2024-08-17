resource "azurerm_user_assigned_identity" "uai" {
  location            = azurerm_resource_group.rg.location
  name                = "identity-${local.resource_token}"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "openai_backend" {
  count                            = try(local.is_default_workspace ? 0 : 1, 0)
  principal_id                     = azurerm_user_assigned_identity.uai.principal_id
  role_definition_name             = "Cognitive Services OpenAI User"
  scope                            = azurerm_cognitive_account.cog.id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "openai_user" {
  count                = try(local.is_default_workspace ? 0 : 1, 0)
  principal_id         = var.principal_id
  role_definition_name = "Cognitive Services OpenAI User"
  scope                = azurerm_cognitive_account.cog.id
}

resource "azurerm_role_assignment" "aisearchdata_backend" {
  count                            = try(local.is_default_workspace ? 0 : 1, 0)
  principal_id                     = azurerm_user_assigned_identity.uai.principal_id
  role_definition_name             = "Search Index Data Contributor"
  scope                            = azurerm_search_service.search.id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aisearchdata_user" {
  count                = try(local.is_default_workspace ? 0 : 1, 0)
  principal_id         = var.principal_id
  role_definition_name = "Search Index Data Contributor"
  scope                = azurerm_search_service.search.id
}

resource "azurerm_role_assignment" "aisearchservice_backend" {
  count                            = try(local.is_default_workspace ? 0 : 1, 0)
  principal_id                     = azurerm_user_assigned_identity.uai.principal_id
  role_definition_name             = "Search Service Contributor"
  scope                            = azurerm_search_service.search.id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aisearchservice_user" {
  count                = try(local.is_default_workspace ? 0 : 1, 0)
  principal_id         = var.principal_id
  role_definition_name = "Search Service Contributor"
  scope                = azurerm_search_service.search.id
}

# This is a bit of a hack to get a service principal for the docker-compose user
# so that we can use it to authenticate to the Azure Cognitive Services and Azure Search
# from within the container and still leverage the azure.identity DefaultAzureCredential.
# The DefaultAzureCredential will look for the AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, and AZURE_TENANT_ID when falling back to the EnvironmentCredential.
# In Azure, a workload identity is used instead of a service principal.
# resource "azuread_application_registration" "docker_compose_user" {
#   display_name = "example"
# }

# resource "time_rotating" "docker_compose_user" {
#   rotation_days = 7
# }

# resource "azuread_application_password" "docker_compose_user" {
#   application_id = azuread_application_registration.docker_compose_user.id
#   rotate_when_changed = {
#     rotation = time_rotating.docker_compose_user.id
#   }
# }

# resource "azuread_service_principal" "docker_compose_user" {
#   client_id                    = azuread_application_registration.docker_compose_user.client_id
#   app_role_assignment_required = false
#   owners                       = [data.azurerm_client_config.current.object_id]
# }

# resource "azurerm_role_assignment" "openai_user_for_docker_compose_user" {
#   count                = try(local.is_default_workspace ? 0 : 1, 0)
#   principal_id         = azuread_service_principal.docker_compose_user.object_id
#   role_definition_name = "Cognitive Services OpenAI User"
#   scope                = azurerm_cognitive_account.cog.id
# }

# resource "azurerm_role_assignment" "aisearchservice_user_user_for_docker_compose_user" {
#   count                = try(local.is_default_workspace ? 0 : 1, 0)
#   principal_id         = azuread_service_principal.docker_compose_user.object_id
#   role_definition_name = "Search Index Data Reader"
#   scope                = azurerm_search_service.search.id
# }
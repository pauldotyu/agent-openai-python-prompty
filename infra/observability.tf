resource "azurerm_monitor_workspace" "example" {
  count               = local.deploy_observability_tools ? 1 : 0
  name                = "amon-${local.resource_token}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_log_analytics_workspace" "example" {
  count               = local.deploy_observability_tools ? 1 : 0
  name                = "alog-${local.resource_token}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "applicationinsights" {
  count               = local.deploy_observability_tools ? 1 : 0
  name                = "ai-${local.resource_token}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.example[0].id
  tags                = local.tags
}

resource "azurerm_dashboard_grafana" "example" {
  count                 = local.deploy_observability_tools ? 1 : 0
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  name                  = "graf-${local.resource_token}"
  grafana_major_version = 10

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.example[0].id
  }
}

resource "azurerm_role_assignment" "grafana1" {
  count                = local.deploy_observability_tools ? 1 : 0
  scope                = azurerm_dashboard_grafana.example[0].id
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Grafana Admin"
}

resource "azurerm_role_assignment" "grafana2" {
  count                = local.deploy_observability_tools ? 1 : 0
  scope                = azurerm_resource_group.rg.id
  principal_id         = azurerm_dashboard_grafana.example[0].identity[0].principal_id
  role_definition_name = "Monitoring Data Reader"
}
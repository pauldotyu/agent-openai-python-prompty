resource "azapi_resource" "aks" {
  type                      = "Microsoft.ContainerService/managedClusters@2024-06-02-preview"
  parent_id                 = azurerm_resource_group.rg.id
  location                  = azurerm_resource_group.rg.location
  name                      = "aks-${local.resource_token}"
  schema_validation_enabled = false

  body = jsonencode({
    identity = {
      type = "SystemAssigned"
    },
    properties = {
      agentPoolProfiles = [
        {
          name                = "systempool"
          count               = 3
          vmSize              = "Standard_DS4_v2"
          osType              = "Linux"
          mode                = "System"
          orchestratorVersion = "1.30.3"
        }
      ]
      kubernetesVersion = "1.30.3"
      addonProfiles = {
        omsagent = {
          enabled = true
          config = {
            logAnalyticsWorkspaceResourceID = azurerm_log_analytics_workspace.example[0].id
            useAADAuth                      = "true"
          }
        }
      }
      azureMonitorProfile = {
        metrics = {
          enabled = true,
          kubeStateMetrics = {
            metricLabelsAllowlist      = "",
            metricAnnotationsAllowList = ""
          }
        },
        containerInsights = {
          enabled                         = true,
          logAnalyticsWorkspaceResourceId = azurerm_log_analytics_workspace.example[0].id
        }
      }
    }
    sku = {
      name = "Automatic"
      tier = "Standard"
    }
  })

  response_export_values = [
    "properties.identityProfile.kubeletidentity.objectId",
    "properties.oidcIssuerProfile.issuerURL",
    "properties.nodeResourceGroup"
  ]
}

# allow yourself to access the AKS cluster
resource "azurerm_role_assignment" "aks2" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = azapi_resource.aks.id
}

# attach the container registry to the AKS cluster
resource "azurerm_role_assignment" "aks3" {
  principal_id         = jsondecode(azapi_resource.aks.output).properties.identityProfile.kubeletidentity.objectId
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr[0].id
}
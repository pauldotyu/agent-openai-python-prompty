resource "azurerm_dns_zone" "dns" {
  name                = "${local.resource_token}.com"
  resource_group_name = azurerm_resource_group.rg.name
}
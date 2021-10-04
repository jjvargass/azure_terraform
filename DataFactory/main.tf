terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.78.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

# Create a resource group
resource "azurerm_resource_group" "sds-rg01-dev-eastUS" {
  name     = "sds-rg01-dev-eastUS"
  location = "East  US"
}
# -- --
# Key Vault
# -- --
resource "azurerm_key_vault" "sds-kv01-dev-eastUS" {
  name                = "sds-kv01-dev-eastUS"
  location            = azurerm_resource_group.sds-rg01-dev-eastUS.location
  resource_group_name = azurerm_resource_group.sds-rg01-dev-eastUS.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"

  tags = {
    "environment"      = "dev"
  }

}

# Key Vault Access Policy del creador el key Vault (Cliente).
resource "azurerm_key_vault_access_policy" "sds-kvap01-dev-client" {
  key_vault_id = azurerm_key_vault.sds-kv01-dev-eastUS.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    # Key Management Operations
    "get",
    "list",
    "update",
    "create",
    "import",
    "delete",
    "recover",
    "backup",
    "restore",
    # Cryptographic Operations
    # "decrypt",
    # "encrypt",
    # "unwrapKey",
    # "wrapKey",
    # "verify",
    # "sign",
    # Privileged Key Operations
    # "purge",
  ]

  secret_permissions = [
    # Secret Management Operations
    "get",
    "list",
    "set",
    "delete",
    "recover",
    "backup",
    "restore",
    # Privileged Secret Operations
    # "purge",
  ]

  certificate_permissions = [
    # Certificate Management Operations
    "get",
    "list",
    "update",
    "create",
    "import",
    "delete",
    "recover",
    "backup",
    "restore",
    "managecontacts",
    "manageissuers",
    "getissuers",
    "listissuers",
    "setissuers",
    "deleteissuers",
    # Privileged Certificate Operations
    # "purge",
  ]

}

# -- --
# Storage Account
# El nombre solo permite minusculas y numeros | sds-st01-dev-eastUS => sdsst01deveastus
# -- --
resource "azurerm_storage_account" "sdsst01deveastus" {
  name                     = "sdsst01deveastus"
  resource_group_name      = azurerm_resource_group.sds-rg01-dev-eastUS.name
  location                 = azurerm_resource_group.sds-rg01-dev-eastUS.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "dev"
  }

}

# Container - Data Lake Store
resource "azurerm_storage_container" "sds-dls01-dev-eastUS" {
  name                  = "sds-dls01-dev-eastUS"
  storage_account_name  = azurerm_storage_account.sdsst01deveastus.name
  container_access_type = "private"
}

# access policy del storage container (creo que no es necesario)

# resource "azurerm_key_vault_access_policy" "sds-kvap01-dev-eastUS" {
#   key_vault_id = azurerm_key_vault.sds-kv01-dev-eastUS.id
#   tenant_id    = data.azurerm_client_config.current.tenant_id
#   object_id    = azurerm_storage_account.sdsst01deveastus.identity.0.principal_id

#   secret_permissions = [
#     "get",
#     "list",
#   ]
# }

# Secreto - connection string de storage container en Key Vault
resource "azurerm_key_vault_secret" "sds-sect01-dev-connection-string-st01" {
  name         = "sds-sect01-dev-connection-string-st01"
  value        = azurerm_storage_account.sdsst01deveastus.primary_connection_string
  key_vault_id = azurerm_key_vault.sds-kv01-dev-eastUS.id
}

# -- --
# eee
# -- --

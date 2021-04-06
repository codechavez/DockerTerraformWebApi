#############################################################################
# VARIABLES
#############################################################################

variable "resource_group_name" {
  type = string
}

variable "service_plan_tier" {
  type = string
}

variable "service_plan_size" {
  type = string
}

variable "location" {
  type    = string
  default = "westus2"
}

locals {
  full_rg_name  = "${terraform.workspace}-${var.resource_group_name}"
  full_app_name = "${terraform.workspace}-__app_name__"
  app_name      = "__app_name__"
}
  
#############################################################################
# BACKEND
#############################################################################

terraform {
  backend "azurerm" {
    storage_account_name = __terra_storage_account_name__
    container_name       = __terra_storage_container_name__
    key                  = "${terraform.workspace}.terraform.tfstate"
    access_key           = __terra_storage_key__
  }
}

#############################################################################
# PROVIDERS
#############################################################################

provider "azurerm" {
  version = "~> 2.0"
  features {}
}

#############################################################################
# RESOURCES
#############################################################################

resource "azurerm_resource_group" "app" {
  name      = local.full_rg_name
  location  = var.location

  tags = {
    environment = terraform.workspace
    system     = "Demo"
  }
}

resource "azurerm_app_service_plan" "app" {
  name                = "${local.full_app_name}-plan"
  location            = "${azurerm_resource_group.app.location}"
  resource_group_name = "${azurerm_resource_group.app.name}"
  kind                = "Linux"
  reserved            = true
  
  sku {
    tier = "Standard"
    size = "S1"
  }

  tags = {
    environment = terraform.workspace
    system     = "Demo"
    container   = "Docker"
  }
}

resource "azurerm_application_insights" "app" {
  name                = "${local.full_app_name}-logs"
  location            = var.location
  resource_group_name = azurerm_resource_group.app.name
  application_type    = "web"
  retention_in_days   = 90

  tags = {
    environment = terraform.workspace
    system     = "Demo"
    container   = "Docker"
  }
}

resource "azurerm_app_service" "app" {
  name                = local.full_app_name
  resource_group_name = azurerm_resource_group.app.name
  location            = var.location
  app_service_plan_id = azurerm_app_service_plan.app.id

  site_config {
    always_on         = "true"
    linux_fx_version  = "DOCKER|__azure_registry__/${local.app_name}:latest"
  }

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"      = "${azurerm_application_insights.app.instrumentation_key}",
    "WEBSITE_TIME_ZONE"                   = "Pacific Standard Time"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = false
    "DOCKER_REGISTRY_SERVER_URL"          = "__azure_registry__"
    "DOCKER_REGISTRY_SERVER_USERNAME"     = "__azure_registry_user__"
    "DOCKER_REGISTRY_SERVER_PASSWORD"     = "__azure_registry_pwd__"
  }
  
  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = terraform.workspace
    system     = "Demo"
    container   = "Docker"
  }
}

output "app_identity_key" {
  value = azurerm_app_service.app.identity
}

output "app_iden_key_compare" {
    value = azurerm_app_service.app.identity[0].principal_id
}

data "azurerm_key_vault" "vault" {
  name                = "teslacodenetsecurekeys"
  resource_group_name = "SecureKeysGroup"
}

resource "azurerm_key_vault_access_policy" "apppolicy" {
  key_vault_id = data.azurerm_key_vault.vault.id
  tenant_id    = "b266e245-882e-4412-8460-70216fd29b38"
  object_id    = "${azurerm_app_service.app.identity[0].principal_id}"

  secret_permissions = [
    "Get",
    "List"
  ]
}
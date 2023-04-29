 terraform {
  required_version = ">= 0.11" 
 backend "azurerm" {
  storage_account_name = "__terraformstorageaccount__"
    container_name       = "terraform"
    key                  = "terraform.tfstate"
	access_key  ="__storagekey__"
	}
	}
  provider "azurerm" {
  features {}
}

#create the resource group
resource "azurerm_resource_group" "dev" {
  name     = "la-tfdeploy-rg"
  location = "East US"
}

#create the storage account for Logic App
resource "azurerm_storage_account" "dev" {
  name                     = "logicapptestsa"
  resource_group_name      = azurerm_resource_group.dev.name
  location                 = azurerm_resource_group.dev.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

#create the app service plan
resource "azurerm_app_service_plan" "dev" {
  name                = "logicapp-test-service-plan"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  kind                = "elastic"


  sku {
    tier = "WorkflowStandard"
    size = "WS1"
  }
}

#create the log analytics workspace for applicatin insights
resource "azurerm_log_analytics_workspace" "dev" {
    name                = "logic-app-test-log-workspace"
    location            = azurerm_resource_group.dev.location
    resource_group_name = azurerm_resource_group.dev.name
    sku                 = "PerGB2018"
    retention_in_days   = 30
}

#create the application insights
resource "azurerm_application_insights" "dev" {
  name                     = "logicapp-test-huidong"
  location                 = azurerm_resource_group.dev.location
  resource_group_name      = azurerm_resource_group.dev.name
  application_type         = "web"
  workspace_id             = azurerm_log_analytics_workspace.dev.id
}

#create the standard Logic App with application insights and system managed identity enabled
resource "azurerm_logic_app_standard" "dev" {
  name                       = "logicapp-test-huidong"
  location                   = azurerm_resource_group.dev.location
  resource_group_name        = azurerm_resource_group.dev.name
  app_service_plan_id        = azurerm_app_service_plan.dev.id
  storage_account_name       = azurerm_storage_account.dev.name
  storage_account_access_key = azurerm_storage_account.dev.primary_access_key

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"        = "node"
    "WEBSITE_NODE_DEFAULT_VERSION"    = "~16"
    "APPINSIGHTS_INSTRUMENTATIONKEY"  = azurerm_application_insights.dev.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.dev.connection_string
  }
  
  identity {
    type = "SystemAssigned"
  }
}
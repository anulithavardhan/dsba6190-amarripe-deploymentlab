// Tags
locals {
  tags = {
    owner       = var.tag_department
    region      = var.tag_region
    environment = var.environment
  }
}

// Existing Resources

/// Subscription ID

data "azurerm_subscription" "current" {
}

// Random Suffix Generator

resource "random_integer" "deployment_id_suffix" {
  min = 100
  max = 999
}

// Resource Group

resource "azurerm_resource_group" "rg" {
  name     = "${var.class_name}-amarripe-${var.environment}-04-rg"
  location = var.location

  tags = local.tags
}


// Storage Account

resource "azurerm_storage_account" "storage" {
  name                     = "${var.class_name}${var.student_name}${var.environment}${random_integer.deployment_id_suffix.result}st"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.tags
}
resource "azurerm_application_insights" "example" {
  name                = "workspace-example-ai-amarripe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

resource "azurerm_key_vault" "example" {
  name                = "anu-workspacevault-new4"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_subscription.current.tenant_id
  sku_name            = "premium"
}


resource "azurerm_machine_learning_workspace" "example" {
  name                    = "machine-learning-ws-amarripe"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  application_insights_id = azurerm_application_insights.example.id
  key_vault_id            = azurerm_key_vault.example.id
  storage_account_id      = azurerm_storage_account.storage.id

  identity {
    type = "SystemAssigned"
  }
}


resource "azurerm_cosmosdb_account" "db" {
  name                = "tfex-cosmos-db-${random_integer.deployment_id_suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover = true

  capabilities {
    name = "EnableAggregationPipeline"
  }

  capabilities {
    name = "mongoEnableDocLevelTTL"
  }

  capabilities {
    name = "MongoDBv3.4"
  }

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = "eastus"
    failover_priority = 1
  }

  geo_location {
    location          = "westus"
    failover_priority = 0
  }
}

resource "azurerm_app_service_plan" "webapp_plan" {
  name                = "webapp-plan-amarripe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku {
    tier = "Free"
    size = "F1"
  }
}

resource "azurerm_app_service" "webapp" {
  name                = "amarripe-webapp-new"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.webapp_plan.id
}

output "webapp_url" {
  value = azurerm_app_service.webapp.default_site_hostname
}
resource "azurerm_public_ip" "firewall_public_ip" {
  name                = "amarripe-firewall-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"

  tags = local.tags
}

// Azure Firewall

resource "azurerm_firewall" "firewall" {
  name                = "amarripe-firewall"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "AZFW_Hub"
  ip_configuration {
    name                          = "amarripe-firewall-ip"
    subnet_id                     = var.subnet_id
    public_ip_address_id          = azurerm_public_ip.firewall_public_ip.id
    provisioning_state_transition = "Succeeded"
  }

  tags = local.tags
}
In the code above, the "azurerm_resource_group" resource creates a new resource group with the name "amarripe-firewall-rg". The "azurerm_public_ip" resource creates a new public IP address with the name "amarripe-firewall-pip". The "azurerm_firewall" resource creates a new Azure Firewall with the name "amarripe-firewall". It uses the IP address created by the "azurerm_public_ip" resource and attaches it to the firewall's IP configuration. The "sku" property specifies the pricing tier of the firewall, and in this case, it uses the "AZFW_Hub" SKU, which is a cheaper option. Finally, the tags are defined in




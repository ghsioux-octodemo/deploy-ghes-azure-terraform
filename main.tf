########################################
## Common, minimal required resources ##
########################################

resource "random_pet" "ghes_random_pet" {}

resource "azurerm_resource_group" "ghes_rg" {
  location = var.resource_group_location
  name     = format("%s-%s", var.resource_group_name_prefix, random_pet.ghes_random_pet.id)
}

# Create virtual network
resource "azurerm_virtual_network" "ghes_network" {
  name                = "ghesVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.ghes_rg.location
  resource_group_name = azurerm_resource_group.ghes_rg.name

   dns_servers = ["1.1.1.1"]  
}

# Create subnet
resource "azurerm_subnet" "ghes_subnet" {
  name                 = "ghesSubnet"
  resource_group_name  = azurerm_resource_group.ghes_rg.name
  virtual_network_name = azurerm_virtual_network.ghes_network.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.ghes_rg.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "ghes_storage_account" {
  # checkov:skip=CKV_AZURE_33: Ensure Storage logging is enabled for Queue service for read, write and delete requests
  # checkov:skip=CKV2_AZURE_1: Ensure storage for critical data are encrypted with Customer Managed Key
  # checkov:skip=CKV2_AZURE_18: Ensure that Storage Accounts use customer-managed key for encryption
  # checkov:skip=CKV_AZURE_59: Ensure that Storage accounts disallow public access
  # checkov:skip=CKV_AZURE_190: Ensure that Storage blobs restrict public access
  # checkov:skip=CKV_AZURE_197: Ensure that Storage Accounts use replication
  # checkov:skip=CKV_AZURE_206: Ensure that Storage Accounts use replication
  name                     = "ghesdia"
  location                 = azurerm_resource_group.ghes_rg.location
  resource_group_name      = azurerm_resource_group.ghes_rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  network_rules {
    virtual_network_subnet_ids = [azurerm_subnet.ghes_subnet.id]
    default_action             = "Deny"
  }
}

# Create Network Security Group
resource "azurerm_network_security_group" "ghes_nsg" {
  name                = "ghesNetworkSecurityGroup"
  location            = azurerm_resource_group.ghes_rg.location
  resource_group_name = azurerm_resource_group.ghes_rg.name
}

# Add Network Security Rules to the Network Security Group
resource "azurerm_network_security_rule" "ghes_nsg_secrules" {
  for_each                    = local.nsgrules
  name                        = each.value.name
  direction                   = "Inbound"
  access                      = "Allow"
  priority                    = each.value.priority
  protocol                    = each.value.protocol
  source_port_range           = "*"
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.ghes_rg.name
  network_security_group_name = azurerm_network_security_group.ghes_nsg.name
}

######################################
## GHES VM and associated resources ##
######################################

# Create GHES public IPs
resource "azurerm_public_ip" "ghes_public_ip" {
  name                = "ghesPublicIP"
  location            = azurerm_resource_group.ghes_rg.location
  resource_group_name = azurerm_resource_group.ghes_rg.name
  allocation_method   = "Static"
  domain_name_label   = format("%s-%s", var.ghes_fqdn_prefix, random_pet.ghes_random_pet.id)
}

# Create GHES network interface
resource "azurerm_network_interface" "ghes_nic" {
  # checkov:skip=CKV_AZURE_119: Ensure that Network Interfaces don't use public IPs 
  name                = "ghesNIC"
  location            = azurerm_resource_group.ghes_rg.location
  resource_group_name = azurerm_resource_group.ghes_rg.name

  ip_configuration {
    name                          = "ghes_nic_configuration"
    subnet_id                     = azurerm_subnet.ghes_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ghes_public_ip.id
  }
}

# Connect the security group to the GHES network interface
resource "azurerm_network_interface_security_group_association" "ghes_nsg_nic_association" {
  network_interface_id      = azurerm_network_interface.ghes_nic.id
  network_security_group_id = azurerm_network_security_group.ghes_nsg.id
}

# Create GHES virtual machine
resource "azurerm_linux_virtual_machine" "ghes_vm" {
  # checkov:skip=CKV_AZURE_179: Ensure VM agent is installed
  name                  = "ghesVM"
  location              = azurerm_resource_group.ghes_rg.location
  resource_group_name   = azurerm_resource_group.ghes_rg.name
  network_interface_ids = [azurerm_network_interface.ghes_nic.id]
  size                  = var.ghes_vm_size

  os_disk {
    name                 = "ghesOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "GitHub"
    offer     = "GitHub-Enterprise"
    sku       = "GitHub-Enterprise"
    version   = var.ghes_release
  }

  computer_name                   = "ghes"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ghes_admin_ssh_pubkey
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.ghes_storage_account.primary_blob_endpoint
  }

  allow_extension_operations = false
}

# Create GHES data disk
resource "azurerm_managed_disk" "ghes_data_disk" {
  # checkov:skip=CKV_AZURE_93: Ensure that managed disks use a specific set of disk encryption sets for the customer-managed key encryption
  name                 = "ghes-data-disk1"
  location             = azurerm_resource_group.ghes_rg.location
  resource_group_name  = azurerm_resource_group.ghes_rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 250
}

# Attach the data disk to the GHES VM
resource "azurerm_virtual_machine_data_disk_attachment" "ghes_data_disk_attachment" {
  managed_disk_id    = azurerm_managed_disk.ghes_data_disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.ghes_vm.id
  lun                = "10"
  caching            = "ReadWrite"
}

##########################################
## GitHub Acions Resources (if enabled) ##
## ghes_use_actions = true              ##
##########################################

# Create storage account for GitHub Actions
resource "azurerm_storage_account" "gh_actions_storage_account" {
  # checkov:skip=CKV_AZURE_33: Ensure Storage logging is enabled for Queue service for read, write and delete requests
  # checkov:skip=CKV2_AZURE_1: Ensure storage for critical data are encrypted with Customer Managed Key
  # checkov:skip=CKV2_AZURE_18: Ensure that Storage Accounts use customer-managed key for encryption
  # checkov:skip=CKV_AZURE_59: Ensure that Storage accounts disallow public access
  # checkov:skip=CKV_AZURE_190: Ensure that Storage blobs restrict public access
  # checkov:skip=CKV_AZURE_197: Ensure that Storage Accounts use replication
  # checkov:skip=CKV_AZURE_206: Ensure that Storage Accounts use replication
  count                    = var.ghes_use_actions ? 1 : 0
  name                     = "gha${random_id.random_id.hex}"
  location                 = azurerm_resource_group.ghes_rg.location
  resource_group_name      = azurerm_resource_group.ghes_rg.name
  account_tier             = "Premium"
  account_kind             = "BlockBlobStorage"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  network_rules {
    virtual_network_subnet_ids = [azurerm_subnet.ghes_subnet.id]
    default_action             = "Deny"
  }
}

############################################
## GitHub Packages Resources (if enabled) ##
## ghes_use_packages = true               ##
############################################

# Create storage account for GitHub Packages
resource "azurerm_storage_account" "gh_packages_storage_account" {
  # checkov:skip=CKV_AZURE_33: Ensure Storage logging is enabled for Queue service for read, write and delete requests
  # checkov:skip=CKV2_AZURE_1: Ensure storage for critical data are encrypted with Customer Managed Key
  # checkov:skip=CKV2_AZURE_18: Ensure that Storage Accounts use customer-managed key for encryption
  # checkov:skip=CKV_AZURE_35: Ensure default network access rule for Storage Accounts is set to deny
  # checkov:skip=CKV_AZURE_59: Ensure that Storage accounts disallow public access
  # checkov:skip=CKV_AZURE_190: Ensure that Storage blobs restrict public access
  # checkov:skip=CKV_AZURE_197: Ensure that Storage Accounts use replication
  # checkov:skip=CKV_AZURE_206: Ensure that Storage Accounts use replication
  count                    = var.ghes_use_packages ? 1 : 0
  name                     = "ghp${random_id.random_id.hex}"
  location                 = azurerm_resource_group.ghes_rg.location
  resource_group_name      = azurerm_resource_group.ghes_rg.name
  account_tier             = "Premium"
  account_kind             = "BlockBlobStorage"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  network_rules {
    # Currently disabled due to https://github.com/hashicorp/terraform-provider-azurerm/issues/2977
    # hence skipping CKV_AZURE_35 above.
    # Network rules must be applied manually after Terraform provisioning.
    # virtual_network_subnet_ids = [azurerm_subnet.ghes_subnet.id]
    # default_action             = "Deny"
    default_action = "Allow"
  }
}

# Create storage container for GitHub Packages
resource "azurerm_storage_container" "gh_packages_container" {
  # checkov:skip=CKV2_AZURE_21: Ensure Storage logging is enabled for Blob service for read requests
  count                 = var.ghes_use_packages ? 1 : 0
  name                  = "packages"
  storage_account_name  = azurerm_storage_account.gh_packages_storage_account[count.index].name
  container_access_type = "private"
}


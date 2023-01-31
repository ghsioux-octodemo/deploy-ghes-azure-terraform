output "resource_group_name" {
  value = azurerm_resource_group.ghes_rg.name
}

output "gh_actions_storage_account" {
  value = var.ghes_use_actions ? azurerm_storage_account.gh_actions_storage_account[0].name : "disabled"
}

output "gh_packages_storage_account" {
  value = var.ghes_use_packages ? azurerm_storage_account.gh_packages_storage_account[0].name : "disabled"
}

output "gh_packages_storage_account_container" {
  value = var.ghes_use_packages ? azurerm_storage_container.gh_packages_container[0].name : "disabled"
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.ghes_vm.public_ip_address
}

output "http_url" {
  value = "http://${azurerm_public_ip.ghes_public_ip.fqdn}"
}

output "ssh_cmdline" {
  value = "ssh -i path/to/private/key azureuser@${azurerm_linux_virtual_machine.ghes_vm.public_ip_address} -p 122"
}

output "replica_public_ip_address" {
  value = var.ghes_high_availability ? azurerm_linux_virtual_machine.ghes_vm_replica[0].public_ip_address : "disabled"
}

output "replica_http_url" {
  value = var.ghes_high_availability ? "http://${azurerm_public_ip.ghes_replica_public_ip[0].fqdn}" : "disabled"
}

output "replica_ssh_cmdline" {
  value = var.ghes_high_availability ? "ssh -i path/to/private/key azureuser@${azurerm_linux_virtual_machine.ghes_vm_replica[0].public_ip_address} -p 122" : "disabled"
}


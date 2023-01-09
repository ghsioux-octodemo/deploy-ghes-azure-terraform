variable "resource_group_location" {
  default     = "westeurope"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  default     = "ghes-rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "ghes_vm_size" {
  default     = "Standard_E4s_v3"
  description = "The Azure VM size for the GitHub Enterprise VM."
}

variable "ghes_release" {
  default     = "3.7.1"
  description = "The GitHub Enterprise Server release."
}

variable "ghes_fqdn_prefix" {
  default     = "ghes"
  description = "The FQDN prefix of the GitHub Enterprise Server DNS entry."
}

variable "ghes_admin_ssh_pubkey" {
  default     = ""
  description = "The RSA SSH public key used to SSH as admin user (azureuser) into the GitHub Enterprise Server VM(s)."
}

variable "ghes_use_actions" {
  default     = false
  type        = bool
  description = "Whether or not to enable GitHub Actions (will create a dedicated storage account if true)"
}

variable "ghes_use_packages" {
  default     = false
  type        = bool
  description = "Whether or not to enable GitHub Packages (will create a dedicated storage account if true)"
}

# Terraform Project for GitHub Enterprise Server (GHES) on Azure

This repository contains the Terraform configuration files for creating a GitHub Enterprise Server (GHES) on Azure.

## Resources

The following resources are created:

- A resource group.
- A virtual network with a specified address space.
- A subnet within the virtual network.
- A storage account for boot diagnostics.
- A network security group with inbound security rules.
- A public IP for the GHES VM.
- A network interface for the GHES VM.
- A Linux virtual machine for the GHES.
- A data disk for the GHES VM.
- A storage account for GitHub Actions (optional).
- A storage account for GitHub Packages (optional).

## Usage

To initialize the Terraform configuration, run:

```bash
terraform init
```

To check the execution plan, run:
```bash
terraform plan
```

To apply the configuration, run:
```bash
terraform apply
```

## Variables

The following variables are required:
* `resource_group_location`: The location where the resource group is to be created.
* `resource_group_name_prefix`: The prefix for the resource group name.
* `ghes_fqdn_prefix`: The prefix for the fully qualified domain name (FQDN) of the GHES VM.
* `ghes_vm_size`: The size of the GHES VM.
* `ghes_release`: The release version of the GHES.
* `ghes_admin_ssh_pubkey`: The public SSH key for the GHES VM admin.
* `ghes_use_actions`: Whether to use GitHub Actions (optional).
* `ghes_use_packages`: Whether to use GitHub Packages (optional).

## Outputs

The following outputs are provided:
* `resource_group_name`: The name of the resource group.
* `ghes_fqdn`: The FQDN of the GHES VM.
* `ghes_admin_username`: The username of the GHES VM admin.
* `ghes_admin_ssh_privkey`: The private SSH key for the GHES VM admin.
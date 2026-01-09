variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "IntLB-RG"
}

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
  default     = "IntLB-VNet"
}

variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}
variable "bastion_name" {
  description = "Azure Bastion host name"
  type        = string
  default     = "myBastionHost"
}

variable "bastion_pip_name" {
  description = "Public IP name for Bastion"
  type        = string
  default     = "myBastionIP"
}
variable "vm_count" {
  description = "Number of backend VMs"
  type        = number
  default     = 3
}

variable "vm_size" {
  description = "Size of the backend VMs"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Local admin username for Windows VMs"
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Local admin password for Windows VMs"
  type        = string
  sensitive   = true
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group" {
  type        = string
  description = "Resource group name"
}

variable "vnet_name" {
  type        = string
  description = "Virtual Network name"
}

variable "address_space" {
  type        = list(string)
  description = "VNet address space"
}

variable "subnet1_name" {
  type        = string
  description = "Subnet 1 name"
}

variable "subnet2_name" {
  type        = string
  description = "Subnet 2 name"
}

variable "subnet1_prefix" {
  type        = string
  description = "CIDR for subnet 1"
}

variable "subnet2_prefix" {
  type        = string
  description = "CIDR for subnet 2"
}

variable "admin_username" {
  type        = string
  description = "VM admin username"
}

variable "admin_password" {
  type        = string
  description = "VM admin password"
  sensitive   = true
}

variable "vm_size" {
  type        = string
  description = "VM size"
  default     = "Standard_B2s"
}

variable "rdp_allowed_ip" {
  type        = string
  description = "Your public IP with /32 to allow RDP"
}

variable "vm01_private_ip" {
  type        = string
  description = "Static private IP for VM01"
}

variable "vm02_private_ip" {
  type        = string
  description = "Static private IP for VM02"
}

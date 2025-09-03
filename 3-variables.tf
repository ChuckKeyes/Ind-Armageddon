variable "project_id" {
  type        = string
  description = "GCP project ID"
  default     = "ck-armageddon"
}

variable "region" {
  type        = string
  default     = "us-east1"
  description = "GCP region for Balerica headquarters"
}

variable "region2" {
  type        = string
  default     = "southamerica-west1"
  description = "GCP region for Balerica secondary region"
}

variable "vpc_name" {
  type        = string
  default     = "balerica-hq-vpc"
  description = "VPC name for headquarters"
}

# NCC hub name (short name)
variable "ncc_hub_name" {
  type        = string
  default     = "balerica-ncc-hub"
  description = "Name of the Network Connectivity Center Hub"
}

# Full NCC hub resource ID
variable "ncc_hub_id" {
  type        = string
  default     = "projects/ck-armageddon/locations/global/hubs/balerica-ncc-hub"
  description = "The full resource ID of the Network Connectivity Center Hub"
}

variable "labels" {
  type = map(string)
  default = {
    environment = "production"
    owner       = "balerica"
  }
  description = "Labels for the NCC Hub"
}

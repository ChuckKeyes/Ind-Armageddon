resource "google_network_connectivity_hub" "balerica_ncc_hub" {
  name        = "balerica-ncc-hub"
  project     = var.project_id
  description = "Central NCC Hub for Balerica HQ"
  # global      = true


  labels = {
    env = "dev"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}


resource "google_compute_network" "hq_vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}


# ###########################################################################


# ##########################################################################
# #       Customer Service Subnetwork 
# ##########################################################################

resource "google_compute_subnetwork" "subnet_customer_service" {
  name          = "subnet-customer-service"
  ip_cidr_range = "10.100.30.0/24"
  region        = var.region
  network       = google_compute_network.hq_vpc.id
}

resource "google_compute_instance" "vm_customer_service" {
  name         = "vm-customer-service"
  machine_type = "e2-micro"
  zone         = "${var.region}-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_customer_service.name
    access_config {}
  }

  tags = ["test-vm"]
}



# ##########################################################################
# #       Production Subnetwork  &  VM
# ##########################################################################

resource "google_compute_subnetwork" "subnet_production" {
  name          = "subnet-production"
  ip_cidr_range = "10.100.10.0/24"
  region        = var.region
  network       = google_compute_network.hq_vpc.id
}

resource "google_compute_instance" "vm_production" {
  name         = "vm-production"
  machine_type = "e2-micro"
  zone         = "${var.region}-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_production.name
    access_config {}
  }

  tags = ["test-vm"]
}

# ############################################################################
# #       Finance Subnetwork   &  VM
# ############################################################################

resource "google_compute_subnetwork" "subnet_finance" {
  name          = "subnet-finance"
  ip_cidr_range = "10.100.20.0/24"
  region        = var.region
  network       = google_compute_network.hq_vpc.id
}

resource "google_compute_instance" "vm_finance" {
  name         = "vm-finance"
  machine_type = "e2-micro"
  zone         = "${var.region}-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_finance.name
    access_config {}
  }

  tags = ["test-vm"]
}

######################################################################
#######  Module      Foreign VPNs   &  HA VPN   ######################
######################################################################
module "edge_to_ind_ncc" {
  source           = "./modules/edge_to_ind_ncc"
  foreign_vpc_name = "class-foreign-vpc"
  prefix           = "class"
  vpn_region       = "us-east1"

  foreign_bgp_asn     = 64514
  hq_bgp_asn          = 65420
  hq_ha_vpn_self_link = "https://www.googleapis.com/compute/v1/projects/ind-armageddon/regions/us-east1/haVpnGateways/hq-ha-vpn"

  shared_secret = "REPLACE_ME"
  linknet1_cidr = "169.254.11.1/30"
  linknet2_cidr = "169.254.12.1/30"
  hq_peer1_ip   = "169.254.11.2"
  hq_peer2_ip   = "169.254.12.2"

  class_project_id = "class-project"
  ind_hub_id       = "projects/ind-armageddon/locations/global/hubs/hq-hub"
}








# #####################################################################
###################   Module  edge_to_ind_ncc   #######################
#######################################################################

# provider "google" {
#   project = "class-project"
#   region  = "us-east1"
# }

# module "edge_to_ind_ncc" {
#   source = "./modules/edge_to_ind_ncc"

#   class_project_id     = "class-project"
#   foreign_vpc_name     = "class-foreign-vpc"
#   prefix               = "class"

#   # From Ind-Armageddon project outputs (see below)
#   ind_hub_id           = "projects/ind-armageddon/locations/global/hubs/hq-hub"
#   hq_ha_vpn_self_link  = "https://www.googleapis.com/compute/v1/projects/ind-armageddon/regions/us-east1/haVpnGateways/hq-ha-vpn"

#   shared_secret  = "REPLACE_ME_STRONG_SECRET"

#   linknet1_cidr  = "169.254.11.1/30"
#   linknet2_cidr  = "169.254.12.1/30"
#   hq_peer1_ip    = "169.254.11.2"
#   hq_peer2_ip    = "169.254.12.2"

#   foreign_bgp_asn = 64514
#   hq_bgp_asn      = 65420

#   extra_advertised_ranges = []
# }

######################################################################################




resource "google_compute_firewall" "allow-internal-test" {
  name    = "allow-internal-test"
  network = google_compute_network.hq_vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  # source_ranges = ["10.100.0.0/16"]  # internal range
  target_tags = ["test-vm"]
}

####################################################################
################    vpc-foreign-testers   ###########################


# resource "google_compute_network" "foreign_vpc" {
#   name                    = "vpc-foreign-testers"
#   auto_create_subnetworks = false
#   routing_mode            = "GLOBAL"
# }

# # Japan Subnet
# resource "google_compute_subnetwork" "subnet_japan" {
#   name          = "subnet-japan"
#   ip_cidr_range = "10.70.0.0/24"
#   region        = "asia-northeast1"
#   network       = google_compute_network.foreign_vpc.id
# }

# # Brazil Subnet
# resource "google_compute_subnetwork" "subnet_brazil" {
#   name          = "subnet-brazil"
#   ip_cidr_range = "10.80.0.0/24"
#   region        = "southamerica-east1"
#   network       = google_compute_network.foreign_vpc.id
# }

# # Italy Subnet
# resource "google_compute_subnetwork" "subnet_italy" {
#   name          = "subnet-italy"
#   ip_cidr_range = "10.90.0.0/24"
#   region        = "europe-west8"
#   network       = google_compute_network.foreign_vpc.id
# }

# # Thailand/Philippines Subnet
# resource "google_compute_subnetwork" "subnet_thailand" {
#   name          = "subnet-thailand"
#   ip_cidr_range = "10.100.0.0/24"
#   region        = "asia-southeast1"
#   network       = google_compute_network.foreign_vpc.id
# }




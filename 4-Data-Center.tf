# Data Center VPC and Subnet (Standalone)
resource "google_compute_network" "datacenter_vpc" {
  name                    = "vpc-datacenter"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}
##################### SUBNETWORK  ###############################
resource "google_compute_subnetwork" "subnet_datacenter" {
  name          = "subnet-datacenter"
  ip_cidr_range = "10.100.60.0/24"
  region        = "us-east1"
  network       = google_compute_network.datacenter_vpc.id
}

######################  VM       ################################

resource "google_compute_instance" "vm_datacenter" {
  name         = "vm-datacenter"
  machine_type = "e2-micro"
  zone         = "us-east1-b"
  tags         = ["vm-test"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_datacenter.name
    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    echo "Datacenter VM is online"
    apt-get update
    apt-get install -y net-tools iputils-ping curl
  EOT
}

##########################   NCC   SPOKE    #########################

# NCC Center Spoke: Data Center VPC
resource "google_network_connectivity_spoke" "datacenter_center_spoke" {
  provider    = google-beta
  name        = "datacenter-center-spoke"
  project     = var.project_id
  location    = "global"
  hub         = var.ncc_hub_id
  description = "Center spoke for the Data Center VPC"

  linked_vpc_network {
    uri                   = google_compute_network.datacenter_vpc.id
    exclude_export_ranges = []
  }
}

# ##############################    FIREWALL   ###################################



resource "google_compute_firewall" "allow_ssh_icmp" {
  name    = "allow-ssh-icmp"
  network = google_compute_network.hq_vpc.name # You’ll need a second one for datacenter_vpc

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["10.100.0.0/16"] # Trust only your private VPC range
  target_tags   = ["vm-test", "nnc-router"]
}

resource "google_compute_firewall" "allow_ssh_icmp_datacenter" {
  name    = "allow-ssh-icmp-dc"
  network = google_compute_network.datacenter_vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vm-test"]
}

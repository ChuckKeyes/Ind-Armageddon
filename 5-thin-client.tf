#############################################
# Thin Client VPC and Subnets
#############################################
resource "google_compute_network" "thin_client_vpc" {
  name                    = "vpc-thin-client"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Thin Client subnet (the jump/router/test VMs live here)
resource "google_compute_subnetwork" "thin_client_subnet" {
  name          = "subnet-thin-client"
  ip_cidr_range = "10.100.40.0/24"
  region        = "us-east1"
  network       = google_compute_network.thin_client_vpc.id
}

# Web subnet INSIDE thin_client_vpc
resource "google_compute_subnetwork" "subnet_web_server" {
  name          = "subnet-web-server"
  ip_cidr_range = "10.50.50.0/24"
  region        = "us-east1"
  network       = google_compute_network.thin_client_vpc.id
}

#############################################
# Web server (no public IP)
#############################################
resource "google_compute_instance" "web_server" {
  name         = "web-01"
  machine_type = "e2-micro"
  zone         = "us-east1-b"
  tags         = ["web-svc", "vm-test"]

  boot_disk {
    initialize_params {
      # Use the image shorthand (valid)
      image = "debian-cloud/debian-12"
      # (Alternatively, use a data source to resolve by family.)
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_web_server.name
    # no access_config => internal-only
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    echo "Hello from web-01 (thin_client_vpc)" > /var/www/html/index.nginx-debian.html
  EOT
}

#############################################
# Thin client "jump" server
#############################################
resource "google_compute_instance" "thinclient_server" {
  name         = "thinclient-server"
  machine_type = "e2-small"
  zone         = "us-east1-b"
  tags         = ["thinclient-jump", "vm-test"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork  = google_compute_subnetwork.thin_client_subnet.name
    access_config {}  # keep if you want a public IP for SSH; otherwise remove and use IAP
  }
}

#############################################
# Firewall (lab-friendly)
#############################################
resource "google_compute_firewall" "allow_thinclient_combined" {
  name    = "allow-thinclient-combined"
  network = google_compute_network.thin_client_vpc.name

  allow { 
    protocol = "icmp" 
  }
  
  allow { 
    protocol = "tcp" 
    ports = ["22", "80", "443"] 
  }

  source_ranges = [
    "10.50.50.0/24",  # Web Server subnet (intra-VPC mgmt / curl tests)
    "0.0.0.0/0"       # Lab-wide SSH/ICMP (tighten later if you want)
  ]

  target_tags = ["vm-test", "ncc-router"]
}

#############################################
# Thin Client Router VM (router appliance)
#############################################
resource "google_compute_instance" "thinclient_router_vm" {
  name           = "thinclient-router-vm"
  machine_type   = "e2-medium"
  zone           = "us-east1-b"
  can_ip_forward = true
  tags           = ["ncc-router", "vm-test"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork  = google_compute_subnetwork.thin_client_subnet.name
    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    echo "Thin Client Router is online"
  EOT
}

#############################################
# NCC Router Appliance Spoke (points at router VM)
#############################################
resource "google_network_connectivity_spoke" "thinclient_router_edge_spoke" {
  provider    = google-beta
  name        = "thinclient-router-edge-spoke"
  project     = var.project_id
  location    = "us-east1"
  hub         = var.ncc_hub_id
  description = "Edge spoke from Thin Client Router VM to NCC"

  linked_router_appliance_instances {
    instances {
      virtual_machine = google_compute_instance.thinclient_router_vm.id
      ip_address      = google_compute_instance.thinclient_router_vm.network_interface[0].network_ip
    }
    site_to_site_data_transfer = true
  }
}

#############################################
# Test VM
#############################################
resource "google_compute_instance" "thinclient_test_vm" {
  name         = "thinclient-vm"
  machine_type = "e2-small"
  zone         = "us-east1-b"
  tags         = ["vm-test"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork  = google_compute_subnetwork.thin_client_subnet.name
    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    echo "Thin Client Test VM is online"
  EOT
}

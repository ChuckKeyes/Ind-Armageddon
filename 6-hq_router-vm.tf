resource "google_compute_instance" "hq_router_vm" {
  name           = "hq-router-vm"
  machine_type   = "e2-medium"
  zone           = "${var.region}-b"
  can_ip_forward = true

  tags = ["ncc-router", "internal", "vm-test"]

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
  echo "HQ Router appliance is online"
  
  # Enable IP forwarding
  sysctl -w net.ipv4.ip_forward=1
  echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

  # Allow forwarding in iptables
  iptables -P FORWARD ACCEPT
EOT


}

resource "google_network_connectivity_spoke" "hq_router_edge_spoke" {
  provider    = google-beta
  name        = "hq-router-edge-spoke"
  project     = var.project_id
  location    = var.region
  hub         = var.ncc_hub_id
  description = "Edge spoke from hq_router_vm for secure connection to Thin Client Server only"

  linked_router_appliance_instances {
    instances {
      virtual_machine = google_compute_instance.hq_router_vm.id
      ip_address      = google_compute_instance.hq_router_vm.network_interface[0].network_ip
    }
    site_to_site_data_transfer = true
  }
}

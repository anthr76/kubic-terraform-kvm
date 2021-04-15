terraform {
  required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.3"
    }
    ct = {
      source  = "poseidon/ct"
      version = "0.8.0"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

provider "ct" {}

# `python3 contrib/download-image.py`
resource "libvirt_volume" "kubic_image" {
  name   = "kubic_image"
  source = "contrib/kubic.qcow2"
}

# Create the same volume between workers and masters
resource "libvirt_volume" "os_volume" {
  name           = "os_volume-${count.index}"
  base_volume_id = libvirt_volume.kubic_image.id
  count          = (var.count_masters + var.count_workers)
}

# Create the same volume between workers and masters
resource "libvirt_volume" "data_volume" {
  name = "data_volume-${count.index}"
  // 6 * 1024 * 1024 * 1024
  size  = 6442450944
  count = (var.count_masters + var.count_workers)
}

# Create a default virsh network.
resource "libvirt_network" "kubic_network" {
  name   = "kubic-network"
  mode   = var.network_mode
  domain = var.dns_domain

  dns {
    enabled = true
  }

  addresses = [var.network_cidr]
}

output "first_master" {
  value = libvirt_domain.kubic_first_master.*.network_interface.0.addresses
}
output "masters" {
  value = libvirt_domain.kubic_master.*.network_interface.0.addresses
}
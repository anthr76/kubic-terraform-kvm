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

resource "libvirt_volume" "kubic_image" {
  name   = "kubic_image"
  source = "./kubic.qcow2"
}

resource "libvirt_volume" "os_volume" {
  name           = "os_volume-${count.index}"
  base_volume_id = libvirt_volume.kubic_image.id
  count          = var.count_vms
}

resource "libvirt_volume" "data_volume" {
  name = "data_volume-${count.index}"

  // 6 * 1024 * 1024 * 1024
  size  = 6442450944
  count = var.count_vms
}

resource "libvirt_network" "kubic_network" {
  name   = "kubic-network"
  mode   = var.network_mode
  domain = var.dns_domain

  dns {
    enabled = true
  }

  addresses = [var.network_cidr]
}

data "ct_config" "base_ignition" {
  count = var.count_vms
  content      = templatefile(
    "base_ignition.yaml",
    { count = count.index
      localanthony_ssh_key = var.localanthony_ssh_key
     }
  )
  strict       = true
  pretty_print = false
}

resource "libvirt_ignition" "ignition" {
  count = var.count_vms
  name = "ignition-${count.index}"
  content = data.ct_config.base_ignition[count.index].rendered
}


resource "libvirt_domain" "kubic_domain" {
  name = "kubic-kubeadm-${count.index}"

  cpu = {
    mode = "host-passthrough"
  }

  memory = var.memory
  vcpu   = var.vcpu

  disk {
    volume_id = element(libvirt_volume.os_volume.*.id, count.index)
  }

  disk {
    volume_id = element(libvirt_volume.data_volume.*.id, count.index)
  }
  console {
    type        = "pty"
    target_port = "0"
    target_type = "virtio"
  }

  network_interface {
    network_name   = "kubic-network"
    hostname       = "kubic-kubeadm-${count.index}"
    wait_for_lease = true
  }

  coreos_ignition = libvirt_ignition.ignition[count.index].id
  count           = var.count_vms
}

output "ips" {
  value = libvirt_domain.kubic_domain.*.network_interface.0.addresses
}

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
  count          = var.count_masters
}

resource "libvirt_volume" "data_volume" {
  name = "data_volume-${count.index}"
  // 6 * 1024 * 1024 * 1024
  size  = 6442450944
  count = var.count_masters
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

data "ct_config" "first_master" {
  count = 1
  content = templatefile(
    "base_ignition.yaml",
    {
      count                = (count.index + 1)
      localanthony_ssh_key = var.localanthony_ssh_key
    }
  )
  snippets = [
    templatefile(
      "init_master.yaml",
      {
        control_plane_ip = var.control_plane_ip
        certificate_key  = var.kubeadm_certificate_key
        token            = var.kubeadm_token
      }
  )]
  strict       = true
  pretty_print = false
}

data "ct_config" "master" {
  count = (var.count_masters - 1) # account for the inital master
  content = templatefile(
    "base_ignition.yaml",
    {
      count                = (count.index + 1)
      localanthony_ssh_key = var.localanthony_ssh_key
    }
  )
  snippets = [
    templatefile(
      "node.yaml.tmpl",
      {
        control_plane_ip = var.control_plane_ip
        certificate_key  = var.kubeadm_certificate_key
        token            = var.kubeadm_token
      }
  )]
  strict       = true
  pretty_print = false
}

resource "libvirt_ignition" "first_master" {
  name    = "first_master-${count.index}"
  count   = 1
  content = data.ct_config.first_master[count.index].rendered
}

resource "libvirt_ignition" "master" {
  count   = (var.count_masters - 1)
  name    = "master-${count.index}"
  content = data.ct_config.master[count.index].rendered
}

resource "libvirt_domain" "kubic_first_master" {
  name  = "kubic-kubeadm-1"
  count = 1

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
    wait_for_lease = true
  }

  coreos_ignition = libvirt_ignition.first_master[count.index].id
}

resource "libvirt_domain" "kubic_master" {
  name = "kubic-kubeadm-${count.index + 2}"

  cpu = {
    mode = "host-passthrough"
  }

  memory = var.memory
  vcpu   = var.vcpu

  disk {
    volume_id = element(libvirt_volume.os_volume.*.id, count.index + 1)
  }

  disk {
    volume_id = element(libvirt_volume.data_volume.*.id, count.index + 1)
  }
  console {
    type        = "pty"
    target_port = "0"
    target_type = "virtio"
  }

  network_interface {
    network_name   = "kubic-network"
    wait_for_lease = true
  }

  coreos_ignition = libvirt_ignition.master[count.index].id
  count           = (var.count_masters - 1)
}

output "first_master" {
  value = libvirt_domain.kubic_first_master.*.network_interface.0.addresses
}
output "masters" {
  value = libvirt_domain.kubic_master.*.network_interface.0.addresses
}
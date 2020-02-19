provider "libvirt" {
  uri = "qemu:///system"
}

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

data "template_file" "cloud_init_disk_user_data" {
  count    = var.count_vms
  template = file("commoninit.cfg")

  vars = {
    hostname = "kubic-${count.index}"
  }
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit-${count.index}.iso"
  pool      = "default"
  user_data = element(data.template_file.cloud_init_disk_user_data.*.rendered, count.index)
  count     = var.count_vms
}

resource "libvirt_domain" "kubic-domain" {
  name = "kubic-kubadm-${count.index}"

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

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  cloudinit = element(libvirt_cloudinit_disk.commoninit.*.id, count.index)
  count     = var.count_vms
}

output "ips" {
  value = libvirt_domain.kubic-domain.*.network_interface.0.addresses
}

data "ct_config" "first_master" {
  count = 1
  content = templatefile(
    "butane/base_ignition.yaml",
    {
      localanthony_ssh_key = var.localanthony_ssh_key
    },
  )
  snippets = [
    templatefile(
      "butane/init_master.yaml",
      {
        control_plane_ip = var.control_plane_ip
        certificate_key  = var.kubeadm_certificate_key
        token            = var.kubeadm_token
        count            = (count.index + 1)
      }
    ),
    templatefile(
      "butane/kube-vip.yaml",
      {
        control_plane_ip = var.control_plane_ip
      }
    ),
  ]
  strict       = true
  pretty_print = false
}

data "ct_config" "master" {
  count = (var.count_masters - 1) # account for the inital master
  content = templatefile(
    "butane/base_ignition.yaml",
    {
      localanthony_ssh_key = var.localanthony_ssh_key
    }
  )
  snippets = [
    templatefile(
      "butane/join_master.yaml",
      {
        control_plane_ip = var.control_plane_ip
        certificate_key  = var.kubeadm_certificate_key
        token            = var.kubeadm_token
        count            = (count.index + 1)
      }
    ),
    templatefile(
      "butane/kube-vip.yaml",
      {
        control_plane_ip = var.control_plane_ip
      }
    ),
  ]
  strict       = true
  pretty_print = false
}

# Create the first master separately for kubeadm init
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
  name  = "kubic-master-1"
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

# Create the rest of the masters
resource "libvirt_domain" "kubic_master" {
  name = "kubic-master-${count.index + 2}"

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
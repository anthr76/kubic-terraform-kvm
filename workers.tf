data "ct_config" "worker" {
  count = var.count_workers
  content = templatefile(
    "butane/base_ignition.yaml",
    {
      localanthony_ssh_key = var.localanthony_ssh_key
    }
  )
  snippets = [
    templatefile(
      "butane/join_worker.yaml",
      {
        control_plane_ip = var.control_plane_ip
        token            = var.kubeadm_token
        count            = (count.index + 1)
      }
    ),]
  strict       = true
  pretty_print = false
}

resource "libvirt_ignition" "worker" {
  count   = (var.count_workers)
  name    = "worker-${count.index}"
  content = data.ct_config.worker[count.index].rendered
}

# Create the workers
resource "libvirt_domain" "kubic_worker" {
  name = "kubic-worker-${count.index + 1}"

  cpu = {
    mode = "host-passthrough"
  }

  memory = var.memory
  vcpu   = var.vcpu

  disk {
    volume_id = element(libvirt_volume.os_volume.*.id, count.index + var.count_masters)
  }

  disk {
    volume_id = element(libvirt_volume.data_volume.*.id, count.index + var.count_masters)
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

  coreos_ignition = libvirt_ignition.worker[count.index].id
  count           = var.count_workers
}
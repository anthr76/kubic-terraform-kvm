variable "dns_domain" {
  description = "DNS domain name"
  default     = "kubic.local"

}

variable "localanthony_ssh_key" {
  description = "SSH user localanthony key"
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2G7k0zGAjd+0LzhbPcGLkdJrJ/LbLrFxtXe+LPAkrphizfRxdZpSC7Dvr5Vewrkd/kfYObiDc6v23DHxzcilVC2HGLQUNeUer/YE1mL4lnXC1M3cb4eU+vJ/Gyr9XVOOReDRDBCwouaL7IzgYNCsm0O5v2z/w9ugnRLryUY180/oIGeE/aOI1HRh6YOsIn7R3Rv55y8CYSqsbmlHWiDC6iZICZtvYLYmUmCgPX2Fg2eT+aRbAStUcUERm8h246fs1KxywdHHI/6o3E1NNIPIQ0LdzIn5aWvTCd6D511L4rf/k5zbdw/Gql0AygHBR/wnngB5gSDERLKfigzeIlCKf Unsafe Shared Key"
  sensitive   = true
}

variable "network_cidr" {
  description = "Network CIDR"
  default     = "10.16.0.0/24"
}

variable "control_plane_ip" {
  description = "IP Address of Control plane endpoint"
  default     = "10.16.0.254"
}

variable "kubeadm_token" {
  type        = string
  description = "The token use for bootstrapping the kubernetes cluster.\nGenerate with: \n$ kubeadm token generate"
  sensitive   = true
}

variable "kubeadm_certificate_key" {
  type        = string
  description = "The key used to encrypt the control-plane certificates.\nGenerate with: \n$ kubeadm alpha certs certificate-key\n"
  sensitive   = true
}

variable "network_mode" {
  description = "Network mode"
  default     = "nat"
}

variable "count_masters" {
  description = "number of masters virtual-machine of same type that will be created"
  default     = 3
}

variable "count_workers" {
  description = "number of workers virtual-machine of same type that will be created"
  default     = 3
}

variable "memory" {
  description = "The amount of RAM (MB) for a node"
  default     = 2048
}

variable "vcpu" {
  description = "The amount of virtual CPUs for a node"
  default     = 2
}

# terraform-kubic-kvm

This is an opionated fork of terraform-kubic-kvm. The goal is to provide e2e cluster creation and kubeadm automation strictly from ignition leveraging several terraform providers such as Matchbox, and CT.

This serves as a testing ground before making it over to my infra repo. Your milleage will vary but perhaps tidbits you find in here you will find useful.

`secret.tfvars` holds secret varibles. This would be used in git-crypt on [infra](github.com/anthr76/infra).

Some gists you might find interesting if you're on a similar path:

* [Kubic/Micro-OS btrfs sub vols](https://gist.github.com/anthr76/739846a7303e1a7e9fd0990c56d139da)
* [AutoYaST which will eventually consume ignition](https://gist.github.com/anthr76/d06ee9ef7e791563597fba708aefdd48)

# About terraform-libvirt

If you want to dive in the Terraform-libvirt API, you can have a look here:

https://github.com/dmacvicar/terraform-provider-libvirt#website-docs

## Prerequisites

You're going to need at least:

* `terraform` >= 1.12
* [`terraform-provider-libvirt`](https://github.com/dmacvicar/terraform-provider-libvirt)


# Usage

Run 

```bash
./contrib/download-image.py
terraform init
terraform plan
terraform apply
```
    
to start the VMs.

Some parameters (like number of virtual machines and parameters of virtual
machines) are configurable by creating a `terraform.tfvars` file which can be
copied from the sample file:

```
cp terraform.tfvars.sample terraform.tfvars
```

Please refer to the `variables.tf` file for the full variables list with
descriptions.


# Setting up Kubernetes cluster

![](https://i.imgur.com/9ysUpJG.png)

Kubeadm is provisoned with an opionated confiuration provided by ignition and butane. Kubeproxy is disabled and cilium CNI is deployed.


# Howto

## Access the cluster locally

```bash
scp -F ssh_config $(terraform output -json | jq -r '.ips.value[0][]'):~/.kube/config ~/.kube/config
k get nodes
```
    
## Using an insecure private registry

```bash
registry_ip="$(terraform output -json | jq -r '.ips.value[0][]'):5000"  # or another IO
for h in $(terraform output -json | jq -r '.ips.value[][]')
do
    cat <<EOF | ssh -F ssh_config $h 'bash -s'
sed -i 's/\[crio\.image\]/[crio.image]\ninsecure_registries = ["$registry_ip"]/g' /etc/crio/crio.conf
grep -C 1 insecure /etc/crio/crio.conf
systemctl restart crio
EOF
done
 ```
 
# References

 * Outdated [Kubic blog entry](https://kubic.opensuse.org/blog/2018-08-20-kubeadm-intro/)

## Provisioning Compute Resources

Note: You must have VirtualBox and Vagrant configured at this point.

Download this github repository and cd into the vagrant folder:

```bash
git clone https://github.com/mahinraza/kubernetes-the-hard-way.git
```

CD into vagrant directory:

```bash
cd kubernetes-the-hard-way/vagrant
```

The `Vagrantfile` is configured for a **minimal resource setup** suitable for learning on a standard laptop. The current configuration uses fixed values optimized for machines with at least **8GB RAM and 4 CPU cores.**

> This will not work if you have less than 8GB of RAM.

Run Vagrant up:

```bash
vagrant up
```

This does the below:

- Deploys 5 VMs - 1 jumphost, 2 controlplane, 1 worker and 1 loadbalancer with the name `kubernetes-ha-*`
    > This is the default settings. This can be changed at the top of the Vagrantfile.
    > If you choose to change these settings, please also update `vagrant/ubuntu/vagrant/setup-hosts.sh`
    > to add the additional hosts to the `/etc/hosts` default before running `vagrant up`.

- Sets IP addresses in the range `192.168.56.x`

    | VM | VM Name | Purpose | IP | Forwarded Port | RAM |
    |-----------|--------------------------|:---------:|-------------:|-----------------:|------:|
    | controlplane01 | kubernetes-ha-controlplane-1 | Master | 192.168.56.41 |  | 2048 |
    | controlplane02 | kubernetes-ha-controlplane-2 | Master | 192.168.56.42 |  | 2048 |
    | node01 | kubernetes-ha-node-1 | Worker | 192.168.56.51 |  | 1024 |
    | loadbalancer | kubernetes-ha-lb | LoadBalancer | 192.168.56.60 |  | 512 |
    | jumphost | kubernetes-ha-jumphost | Jumphost | 192.168.56.71 | 2710 | 2048 |

    > These are the default settings and can be changed in the Vagrantfile.

- Adds a DNS entry to each of the nodes to access internet
    > DNS: 8.8.8.8

- Sets required kernel settings for Kubernetes networking to function correctly.

---

## SSH to the Nodes

There are two ways to SSH into the nodes:

### 1. SSH using Vagrant (Recommended)

From the directory you ran the `vagrant up` command, run `vagrant ssh <vm>`:

```bash
vagrant ssh controlplane01
vagrant ssh controlplane02
vagrant ssh node01
vagrant ssh loadbalancer
vagrant ssh jumphost
```

### 2. SSH Using Node IP

```bash
ssh vagrant@192.168.56.41   # controlplane01
ssh vagrant@192.168.56.42   # controlplane02
ssh vagrant@192.168.56.51   # node01
ssh vagrant@192.168.56.60   # loadbalancer
ssh vagrant@192.168.56.71   # jumphost
```

### 3. SSH on jumphost Using Localhost with Port Forwarding

```bash
ssh -p 2710 vagrant@127.0.0.1   # controlplane01
```

> Username/password: `vagrant/vagrant`

Private key path for each VM:
- `.vagrant/machines/<machine name>/virtualbox/private_key`

---

## Verify Environment

- Ensure all VMs are up.
- Ensure VMs are assigned the above IP addresses.
- Ensure you can SSH into these VMs using the IP and private keys, or `vagrant ssh`.
- Ensure the VMs can ping each other.

```bash
# verify all VMs are running
vagrant status

# verify IPs from inside a VM
vagrant ssh controlplane01
ip addr show enp0s8

# ping other nodes
ping 192.168.56.42   # controlplane02
ping 192.168.56.51   # node01
ping 192.168.56.60   # loadbalancer
```

---

## Troubleshooting Tips

### Network Collision Error

If you see this error:
```
The specified host network collides with a non-hostonly network!
Bridged Network Address: '192.168.56.0'
```

Your WiFi is using the same IP range. Fix by changing `IP_NW` in the Vagrantfile:
```ruby
IP_NW = "192.168.56."   # change if collides with your WiFi
```

### Failed Provisioning

If any of the VMs failed to provision, delete the VM using:

```bash
vagrant destroy <vm>
```

Then re-provision — only missing VMs will be re-provisioned:

```bash
vagrant up
```

If VirtualBox throws a folder rename error:
```
VBoxManage.exe: error: Could not rename the directory...VERR_ALREADY_EXISTS
```

Delete the VM, remove the folder, then re-provision:

```bash
vagrant destroy node02
rmdir "<path-to-vm-folder>\kubernetes-ha-node-2"
vagrant up
```

### Wrong GitHub Account (403 Error)

If you see:
```
remote: Permission to mahinraza/kubernetes-the-hard-way.git denied to Mahin556.
fatal: unable to access ... 403
```

Fix cached credentials:
1. Open **Windows Credential Manager**
2. Remove `git:https://github.com`
3. Push again and login as `mahinraza`

### Provisioner Gets Stuck

If stuck at "Waiting for machine to reboot":

1. Hit `CTRL+C`
2. Kill any running `ruby` process
3. Destroy the stuck VM: `vagrant destroy <vm>`
4. Re-provision: `vagrant up`

---

## Pausing the Environment

You do not need to complete the entire lab in one session.

To shut down all VMs:
```bash
vagrant halt
```

To power on again:
```bash
vagrant up
```

---

Next: [Client tools](../../docs/03-client-tools.md)
Prev: [Prerequisites](01-prerequisites.md)
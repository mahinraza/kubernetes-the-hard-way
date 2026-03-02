# Vagrant

This directory contains the configuration for the virtual machines we will use for the installation.

A few prerequisites are handled by the VM provisioning steps.

## Kernel Settings

1. Install the `br_netfilter` kernel module that permits kube-proxy to manipulate IP tables rules.
1. Add the two tunables `net.bridge.bridge-nf-call-iptables=1` and `net.ipv4.ip_forward=1` also required for successful pod networking.

## DNS settings

1. Set the default DNS server to be Google, as we know this always works.
1. Set up `/etc/hosts` so that all the VMs can resolve each other

## Other settings

1. Install configs for `vim` and `tmux` on controlplane01


## SSH Commands for Your Cluster

### Using Node IP (Host-Only Network)
```bash
# Control Plane Nodes
ssh vagrant@192.168.56.41   # controlplane01
ssh vagrant@192.168.56.42   # controlplane02

# Worker Nodes
ssh vagrant@192.168.56.51   # node01
ssh vagrant@192.168.56.52   # node02

# Load Balancer
ssh vagrant@192.168.56.60   # loadbalancer
```

---

### Using Localhost with Port Forwarding
```bash
# Control Plane Nodes
ssh -p 2711 vagrant@127.0.0.1   # controlplane01
ssh -p 2712 vagrant@127.0.0.1   # controlplane02

# Worker Nodes
ssh -p 2721 vagrant@127.0.0.1   # node01
ssh -p 2722 vagrant@127.0.0.1   # node02

# Load Balancer
ssh -p 2730 vagrant@127.0.0.1   # loadbalancer
```

---

### Quick Reference Table

| Node | IP | Port |
|------|----|------|
| controlplane01 | `192.168.56.41` | `2711` |
| controlplane02 | `192.168.56.42` | `2712` |
| node01 | `192.168.56.51` | `2721` |
| node02 | `192.168.56.52` | `2722` |
| loadbalancer | `192.168.56.60` | `2730` |

> Password for all nodes: `vagrant`
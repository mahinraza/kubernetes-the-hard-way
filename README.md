# Kubernetes The Hard Way

| Status | |
|-|-|
| Forked & Modified by | **Mahin Raza** |
| Original Author | [Kelsey Hightower](https://github.com/kelseyhightower/kubernetes-the-hard-way) |
| Adapted by | [mmumshad](https://github.com/mmumshad/kubernetes-the-hard-way) |
| Last Updated | March 2024 |
| Last Tested | November 2025 |

> This is my personal fork of **Kubernetes The Hard Way**, modified for my own learning journey. I use this to understand how Kubernetes works under the hood — every component, every certificate, every config file.

---

## What is This?

This tutorial walks you through setting up a **fully functional Kubernetes cluster from scratch** on a local machine using VirtualBox and Vagrant — no shortcuts, no `kubeadm`, no automation.

This is **not** for people looking for a quick Kubernetes setup. If that's what you need, check out:
- [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine)
- [Getting Started Guides](http://kubernetes.io/docs/getting-started-guides/)

The whole point is to **understand every step** — from generating TLS certificates to bootstrapping etcd, configuring the API server, and connecting worker nodes manually.

---

## Why I'm Doing This

I'm learning Kubernetes from the ground up to understand:
- How control plane components talk to each other
- How TLS certificates work in a cluster
- How etcd stores cluster state
- How kubeconfig files are structured
- How worker nodes register with the control plane
- How load balancing works across API servers

---

## Important Note

> This challenge is **all about the details.** Miss one tiny step and it breaks. The `cert_verify.sh` script is your best friend — run it every time it suggests and make sure everything shows green before moving on.

If something isn't working — **99.9% of the time you missed a step**, not a bug in the lab. Go back and check carefully.

---

## Cluster Details

This cluster uses:

- [Kubernetes](https://github.com/kubernetes/kubernetes) — Latest version
- [containerd](https://github.com/containerd/containerd) — Container runtime
- [Weave Networking](https://www.weave.works/docs/net/latest/kubernetes/kube-addon/) — Pod networking
- [etcd](https://github.com/coreos/etcd) v3.5.9 — Cluster state store
- [CoreDNS](https://github.com/coredns/coredns) v1.9.4 — DNS for the cluster
- [HAProxy](https://www.haproxy.org/) — Load balancer for API servers
- Pod CIRD:- `10.244.0.0/16`
- Service CIRD:- `10.96.0.0/16`
- Virtual Machine CIDR:- `192.168.56.0/24`

---

### Vagrant Environment

| VM | VM Name | Purpose | IP | Forwarded Port | RAM |
|-----------|--------------------------|:---------:|-------------:|-----------------:|------:|
| controlplane01 | kubernetes-ha-controlplane-1 | Master | 192.168.56.41 |  | 2048 |
| controlplane02 | kubernetes-ha-controlplane-2 | Master | 192.168.56.42 |  | 2048 |
| node01 | kubernetes-ha-node-1 | Worker | 192.168.56.51 |  | 1024 |
| node02 | kubernetes-ha-node-2 | Worker | 192.168.56.52 |  | 1024 |
| loadbalancer | kubernetes-ha-lb | LoadBalancer | 192.168.56.60 |  | 512 |
| jumphost | kubernetes-ha-jumphost | Jumphost | 192.168.56.71 | 2710 | 2048 |

---

## Cluster Layout

```
controlplane01  (2GB RAM, 2 CPU)  ──┐
                                    ├──► loadbalancer (HAProxy)
controlplane02  (2GB RAM, 1 CPU)  ──┘         ↕
                                         kubectl / kubeconfig
node01  (1GB RAM, 1 CPU)
node02  (1GB RAM, 1 CPU)
```

- **2 Control Plane nodes** — run Kubernetes control plane components as OS services (not kubeadm). These are NOT kubectl nodes and won't show in `kubectl get nodes`.
- **2 Worker nodes** — run actual workloads
- **1 Load Balancer** — HAProxy balancing between the two API servers

> Note: We use 2 controlplane nodes instead of the recommended 3 for etcd quorum. This is intentional to save resources while still demonstrating HA load balancing.

---

## Getting Started

- **Windows or Intel Mac** → Start [here](./VirtualBox/docs/01-prerequisites.md) — uses VirtualBox + Vagrant
- **Apple Silicon Mac (M1/M2/M3)** → Start [here](./apple-silicon/docs/01-prerequisites.md) — uses Multipass

---

## My Setup

- OS: Windows
- Hypervisor: VirtualBox + Vagrant
- Shell: Git Bash (MINGW64)
- GitHub: [mahinraza](https://github.com/mahinraza)

---

## Credits

- Original tutorial by [Kelsey Hightower](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- Local VM adaptation by [mmumshad](https://github.com/mmumshad/kubernetes-the-hard-way)
- This fork maintained by **Mahin Raza** for personal learning


```bash
ansible-playbook playbooks/site.yml --tags pki
ansible-playbook playbooks/site.yml --tags pki_distribution
ansible-playbook playbooks/site.yml --tags kubeconfig
ansible-playbook playbooks/site.yml --tags etcd
ansible-playbook playbooks/site.yml --tags loadbalancer
# ansible-playbook playbooks/site.yml --tags control-plane
ansible-playbook playbooks/site.yml --tags masters
ansible-playbook playbooks/site.yml --tags workers
```
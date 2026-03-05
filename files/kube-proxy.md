**You can install kube-proxy on control plane, but in Kubernetes the Hard Way - DON'T.**

## Key Points:

1. **The Rule:**
   - Only install kube-proxy on machines that run kubelet
   - kube-proxy's job is to help PODS connect to services
   - No kubelet = no pods = no need for kube-proxy

2. **In Kubernetes the Hard Way:**
   - Control plane = no kubelet, no pods
   - Control plane runs only: api-server, controller-manager, scheduler
   - Workers run: kubelet, container runtime, kube-proxy

3. **Simple Decision:**
   - If control plane has kubelet → install kube-proxy
   - If control plane has NO kubelet → skip kube-proxy

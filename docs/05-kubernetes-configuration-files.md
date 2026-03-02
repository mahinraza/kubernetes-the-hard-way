# Generating Kubernetes Configuration Files for Authentication

In this lab you will generate [Kubernetes configuration files](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/), also known as "kubeconfigs", which enable Kubernetes clients to locate and authenticate to the Kubernetes API Servers.

Note: It is good practice to use file paths to certificates in kubeconfigs that will be used by the services. When certificates are updated, it is not necessary to regenerate the config files, as you would have to if the certificate data was embedded. Note also that the cert files don't exist in these paths yet - we will place them in later labs.

User configs, like `admin.kubeconfig` will have the certificate info embedded within them.

## Client Authentication Configs

In this section you will generate kubeconfig files for the `controller manager`, `kube-proxy`, `scheduler` clients and the `admin` user.

### Kubernetes Public IP Address

Each kubeconfig requires a Kubernetes API Server to connect to. To support high availability the IP address assigned to the load balancer will be used, so let's first get the address of the loadbalancer into a shell variable such that we can use it in the kubeconfigs for services that run on worker nodes. The controller manager and scheduler need to talk to the local API server, hence they use the localhost address.

[//]: # (host:controlplane01)

```bash
LOADBALANCER=$(dig +short loadbalancer)
echo $LOADBALANCER
```

### The kube-proxy Kubernetes Configuration File

Generate a kubeconfig file for the `kube-proxy` service:

```bash
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
    --server=https://${LOADBALANCER}:6443 \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=/var/lib/kubernetes/pki/kube-proxy.crt \
    --client-key=/var/lib/kubernetes/pki/kube-proxy.key \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
}
```

Results:

```
kube-proxy.kubeconfig
```

Reference docs for kube-proxy [here](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/)

### The kube-controller-manager Kubernetes Configuration File

Generate a kubeconfig file for the `kube-controller-manager` service:

```bash
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=/var/lib/kubernetes/pki/kube-controller-manager.crt \
    --client-key=/var/lib/kubernetes/pki/kube-controller-manager.key \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
}
```

Results:

```
kube-controller-manager.kubeconfig
```

Reference docs for kube-controller-manager [here](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/)

### The kube-scheduler Kubernetes Configuration File

Generate a kubeconfig file for the `kube-scheduler` service:

```bash
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=/var/lib/kubernetes/pki/kube-scheduler.crt \
    --client-key=/var/lib/kubernetes/pki/kube-scheduler.key \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
}
```

Results:

```
kube-scheduler.kubeconfig
```

Reference docs for kube-scheduler [here](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-scheduler/)

### The admin Kubernetes Configuration File

Generate a kubeconfig file for the `admin` user:

```bash
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=admin.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate=admin.crt \
    --client-key=admin.key \
    --embed-certs=true \
    --kubeconfig=admin.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=admin \
    --kubeconfig=admin.kubeconfig

  kubectl config use-context default --kubeconfig=admin.kubeconfig
}
```

Results:

```
admin.kubeconfig
```

Reference docs for kubeconfig [here](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)

##

## Distribute the Kubernetes Configuration Files

Copy the appropriate `kube-proxy` kubeconfig files to each worker instance:

```bash
for instance in node01 node02; do
  echo "=== Copying kube-proxy config to ${instance} ==="
  
  # Copy to home directory first
  scp -o StrictHostKeyChecking=no kube-proxy.kubeconfig ${instance}:~/
  
  # Move to proper location and set permissions
  ssh -o StrictHostKeyChecking=no ${instance} "
    sudo mkdir -p /var/lib/kube-proxy
    sudo mv ~/kube-proxy.kubeconfig /var/lib/kube-proxy/kube-proxy.kubeconfig
    sudo chown root:root /var/lib/kube-proxy/kube-proxy.kubeconfig
    sudo chmod 600 /var/lib/kube-proxy/kube-proxy.kubeconfig
    echo '✓ kube-proxy config installed'
    sudo ls -la /var/lib/kube-proxy/
  "
done
```

Copy the appropriate `admin.kubeconfig`, `kube-controller-manager` and `kube-scheduler` kubeconfig files to each controller instance:

```bash
for instance in controlplane01 controlplane02; do
  echo "=== Copying configs to ${instance} ==="
  
  # Copy all config files to home directory
  scp -o StrictHostKeyChecking=no \
    admin.kubeconfig \
    kube-controller-manager.kubeconfig \
    kube-scheduler.kubeconfig \
    ${instance}:~/
  
  # Move to proper locations and set permissions
  ssh -o StrictHostKeyChecking=no ${instance} "
    # Admin kubeconfig (for kubectl)
    sudo mkdir -p /root/.kube
    sudo mv ~/admin.kubeconfig /root/.kube/config
    sudo chown root:root /root/.kube/config
    sudo chmod 600 /root/.kube/config
    
    # Controller manager kubeconfig
    sudo mkdir -p /var/lib/kubernetes
    sudo mv ~/kube-controller-manager.kubeconfig /var/lib/kubernetes/
    sudo chown root:root /var/lib/kubernetes/kube-controller-manager.kubeconfig
    sudo chmod 600 /var/lib/kubernetes/kube-controller-manager.kubeconfig
    
    # Scheduler kubeconfig
    sudo mv ~/kube-scheduler.kubeconfig /var/lib/kubernetes/
    sudo chown root:root /var/lib/kubernetes/kube-scheduler.kubeconfig
    sudo chmod 600 /var/lib/kubernetes/kube-scheduler.kubeconfig
    
    echo '✓ Config files installed:'
    sudo ls -la /root/.kube/
    sudo ls -la /var/lib/kubernetes/
  "
done

# Verify worker nodes
for instance in node01 node02; do
  echo "=== ${instance} kube-proxy config ==="
  ssh -o StrictHostKeyChecking=no ${instance} "sudo ls -la /var/lib/kube-proxy/"
done

# Verify control plane nodes
for instance in controlplane01 controlplane02; do
  echo "=== ${instance} configs ==="
  ssh -o StrictHostKeyChecking=no ${instance} "
    sudo ls -la /root/.kube/
    sudo ls -la /var/lib/kubernetes/
  "
done
```

## Optional - Check kubeconfigs

At `controlplane01` and `controlplane02` nodes, run the following, selecting option 2

[//]: # (command./cert_verify.sh 2)
[//]: # (command:ssh controlplane02 './cert_verify.sh 2')

```
./cert_verify.sh
```


Next: [Generating the Data Encryption Config and Key](./06-data-encryption-keys.md)<br>
Prev: [Certificate Authority](./04-certificate-authority.md)

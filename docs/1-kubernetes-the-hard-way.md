# **Kubernetes The Hard Way on VirtualBox**

### **Prerequisites**
* If your machine is Windows, Linux(not tested) or Intel Mac. For these machines, we use VirtualBox as the hypervisor, and Vagrant to provision the Virtual Machines.

#### Hardware Requirements
* This lab provisions 6 VMs on your workstation.
* 16GB RAM. It may work with less, but will be slow and may crash unexpectedly.
* 8 core or better CPU e.g. Intel Core-i7/Core-i9, AMD Ryzen-7/Ryzen-9. May work with fewer, but will be slow and may crash unexpectedly.
* 50 GB disk space


#### VirtualBox
* Download and install [VirtualBox](https://www.virtualbox.org/wiki/Downloads) on any one of the supported platforms:
  * Windows
  * Intel Mac
  * Linux

#### Vagrant
* Once VirtualBox is installed you may chose to deploy virtual machines manually on it.
Vagrant provides an easier way to deploy multiple virtual machines on VirtualBox more consistently.
* Download and install [Vagrant](https://www.vagrantup.com/) on your platform.
  * Windows
  * Debian/Ubuntu
  * CentOS
  * Linux
  * Intel Mac

#### Tmux

* [tmux](https://github.com/tmux/tmux/wiki) can be used to run commands on multiple compute instances at the same time. 

  ![tmux screenshot](/images/tmux-screenshot.png)

> Enable synchronize-panes by pressing `CTRL+B` followed by `"` to split the window into two panes. In each pane (selectable with mouse), ssh to the host(s) you will be working with.</br>Next type `CTRL+X` at the prompt to begin sync. In sync mode, the dividing line between panes will be red. Everything you type or paste in one pane will be echoed in the other.<br>To disable synchronization type `CTRL+X` again.</br></br>Note that the `CTRL-X` key binding is provided by a `.tmux.conf` loaded onto the VM by the vagrant provisioner.

<br>

---

### **Lab Environment**

* The labs have been configured with the following networking defaults. It is not recommended to change these. 
* If you change any of these after you have deployed any of the lab, you'll need to completely reset it and start again from the beginning:

  ```bash
  vagrant destroy -f
  vagrant up
  ```

#### Virtual Machine Network

* The network used by VirtualBox virtual machines is set to `192.168.56.0/24` by default.
* To change this network, you need to edit line 27 in your local copy of the Vagrantfile.
* You should not edit the Vagrantfile directly in the GitHub repository.
* Any new network value you choose must not overlap with other network settings in your environment.
* Only the Vagrantfile requires editing when changing the network prefix.
* You do not need to modify any other scripts because the system uses shell variable computations to handle the changes.
* The VM IP addresses and hosts file values are automatically computed based on your new network setting.
* It is recommended that you keep the default pod and service network configurations.
* If you do decide to change the pod or service networks, you will need to edit either the CoreDNS manifest, the Weave networking manifests, or both to accommodate your changes.

#### Pod Network
- The default pod network CIDR is set to `10.244.0.0/16`.
- To change this, you need to open all `.md` files in the `docs` directory.
- Perform a global replace on `POD_CIDR=10.244.0.0/16` with your new CIDR range.
- Ensure your new pod network does not overlap with any other network settings.

#### Service Network
- The default service network CIDR is set to `10.96.0.0/16`
- To change this, open all `.md` files in the `docs` directory
- Perform a global replace on `SERVICE_CIDR=10.96.0.0/16` with your new CIDR range
- Verify that your new service network does not conflict with other network settings
- Additionally, you must edit line 164 in `deployments/coredns.yaml` to update the DNS service address
- The new DNS service address should maintain the same pattern, ending with `.10` (for example, if you change the service network to `10.97.0.0/16`, the DNS address would become `10.97.0.10`)

<br>

---

### **Provisioning Compute Resources/Infrastructure(Jumphost)**

* Download this github repository and cd into the vagrant folder:
  ```bash
  git clone https://github.com/mahinraza/kubernetes-the-hard-way.git
  ```
* CD into vagrant directory:
  ```bash
  cd kubernetes-the-hard-way/vagrant
  ```
* Run Vagrant up:
  ```bash
  vagrant up
  ```

* This does the below:
  * Deploys 6 VMs - 1 jumphost, 2 controlplane, 2 worker and 1 loadbalancer with the name `kubernetes-ha-*`
  * This is the default settings. This can be changed at the top of the Vagrantfile.
  * If you choose to change these settings, please also update [setup-hosts.sh](/vagrant/ubuntu/vagrant/setup-hosts.sh).
  * To add the additional hosts to the `/etc/hosts` default before running `vagrant up`.

* Sets IP addresses in the range `192.168.56.x`.

    | VM | VM Name | Purpose | IP | Forwarded Port | RAM |
    |-----------|--------------------------|:---------:|-------------:|-----------------:|------:|
    | controlplane01 | kubernetes-ha-controlplane-1 | Master | 192.168.56.41 |  | 2048 |
    | controlplane02 | kubernetes-ha-controlplane-2 | Master | 192.168.56.42 |  | 2048 |
    | node01 | kubernetes-ha-node-1 | Worker | 192.168.56.51 |  | 1024 |
    | node02 | kubernetes-ha-node-2 | Worker | 192.168.56.52 |  | 1024 |
    | loadbalancer | kubernetes-ha-lb | LoadBalancer | 192.168.56.60 |  | 512 |
    | jumphost | kubernetes-ha-jumphost | Jumphost | 192.168.56.71 | 2710 | 2048 |

    > These are the default settings and can be changed in the Vagrantfile.

* Adds a DNS entry to each of the nodes to access internet in [update-dns.sh](/vagrant/ubuntu/update-dns.sh).
    > DNS: 8.8.8.8

* Sets required kernel settings for Kubernetes networking to function correctly in [setup-kernel.sh](/vagrant/ubuntu/setup-kernel.sh).

<br>

---

### **Setup SSH between jumphost and all other nodes(Jumphost)**

* Create an SSH key pair for the user who we are logged in as (this is `vagrant` on VirtualBox, `ubuntu` on Apple Silicon).
* Copy the public key of this pair to the other nodes to permit us to use password-less SSH (and SCP).
* Generate SSH key pair on `jumphost` node:
  ```bash
  ssh-keygen -t ed25519 -b 4096 -f ~/.ssh/kubernetes -N ""
  ```
* Copy the key to the other hosts. Run the below command to copy public key to all the nodes.
  ```bash
  for host in localhost controlplane01 controlplane02 loadbalancer node01 node02; do
    echo "Setting up SSH for $host..."
    sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/kubernetes.pub vagrant@$host
  done
  ```
  * The password is:
    * VirtualBox - `vagrant`
    * Apple Silicon: `ubuntu`

  > The option `-o StrictHostKeyChecking=no` tells it not to ask if you want to connect to a previously unknown host. Not best practice in the real world, but speeds things up here.

  > `$(whoami)` selects the appropriate user name to connect to the remote VMs. On VirtualBox this evaluates to `vagrant`; on Apple Silicon it is `ubuntu`.

* To Verify connection run the below script.
  ```bash
  for host in localhost controlplane01 controlplane02 loadbalancer node01 node02; do
    ssh -o ConnectTimeout=3 -o ConnectionAttempts=2 -o StrictHostKeyChecking=no -o PasswordAuthentication=no -o BatchMode=yes -i ~/.ssh/kubernetes vagrant@$host "echo 'OK'"
  done 
  ```

<br>

---

### **Managing the Lab Environment(from jumphost)**

#### There are 3 ways to SSH into the nodes:

* **SSH using Vagrant (Recommended)**: From the directory you ran the `vagrant up` command, run `vagrant ssh <vm>`:
  ```bash
  vagrant ssh controlplane01
  vagrant ssh controlplane02
  vagrant ssh node01
  vagrant ssh node02
  vagrant ssh loadbalancer
  vagrant ssh jumphost
  ```

* **SSH on jumphost Using Localhost with Port Forwarding**
  ```bash
  ssh -p 2710 -i ~/.ssh/kubernetes vagrant@127.0.0.1   # jumphost
  ```

* **SSH Using Node IP**
  ```bash
  ssh -i ~/.ssh/kubernetes vagrant@192.168.56.41   # controlplane01
  ssh -i ~/.ssh/kubernetes vagrant@192.168.56.42   # controlplane02
  ssh -i ~/.ssh/kubernetes vagrant@192.168.56.51   # node01
  ssh -i ~/.ssh/kubernetes vagrant@192.168.56.52   # node02
  ssh -i ~/.ssh/kubernetes vagrant@192.168.56.60   # loadbalancer
  ssh -i ~/.ssh/kubernetes vagrant@192.168.56.71   # jumphost
  ```

* Username/password: `vagrant/vagrant`
* Private key path for each VM: `.vagrant/machines/<machine name>/virtualbox/private_key`


#### Verify Environment

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
  ping 192.168.56.41   # controlplane01
  ping 192.168.56.42   # controlplane02
  ping 192.168.56.51   # node01
  ping 192.168.56.52   # node02
  ping 192.168.56.60   # loadbalancer
  ```
  ```bash
  # Pausing the Environment
  #You do not need to complete the entire lab in one session.
  #To shut down all VMs:
  vagrant halt
  
  #To power on again:
  vagrant up
  ```


#### Troubleshooting Tips

##### Network Collision Error
* If you see this error:
  ```
  The specified host network collides with a non-hostonly network!
  Bridged Network Address: '192.168.56.0'
  ```
* Your WiFi is using the same IP range. Fix by changing `IP_NW` in the Vagrantfile:
  ```ruby
  IP_NW = "192.168.56."   # change if collides with your WiFi
  ```

##### Failed Provisioning
* If any of the VMs failed to provision, delete the VM using:
  ```bash
  vagrant destroy <vm>
  ```
  Then re-provision — only missing VMs will be re-provisioned:
  ```bash
  vagrant up
  ```
* If VirtualBox throws a folder rename error:
  ```
  VBoxManage.exe: error: Could not rename the directory...VERR_ALREADY_EXISTS
  ```
  Delete the VM, remove the folder, then re-provision:
  ```bash
  vagrant destroy node02
  rmdir "<path-to-vm-folder>\kubernetes-ha-node-2"
  vagrant up
  ```

##### Wrong GitHub Account (403 Error)
* If you see:
  ```
  remote: Permission to mahinraza/kubernetes-the-hard-way.git denied to Mahin556.
  fatal: unable to access ... 403
  ```
  Fix cached credentials:
  1. Open **Windows Credential Manager**
  2. Remove `git:https://github.com`
  3. Push again and login as `mahinraza`

##### Provisioner Gets Stuck
* If stuck at "Waiting for machine to reboot":
  1. Hit `CTRL+C`
  2. Kill any running `ruby` process
  3. Destroy the stuck VM: `vagrant destroy <vm>`
  4. Re-provision: `vagrant up`

<br>

---

### **Installing the Client Tools(from jumphost)**

* From this point forward, all steps are identical for both VirtualBox and Apple Silicon environments
* The instructions now focus exclusively on configuring Kubernetes itself on the Linux hosts that have already been provisioned
* You should begin by logging into the `jumphost` node
* The login method differs based on your platform:
  - For VirtualBox: Use `vagrant ssh jumphost`
  - For Apple Silicon: Use `multipass shell jumphost`
* This marks the transition point where platform-specific provisioning is complete and common Kubernetes configuration begins.


#### Install kubectl

* The [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl) command line utility is used to interact with the Kubernetes API Server. Download and install `kubectl` from the official release binaries:
* Reference: [https://kubernetes.io/docs/tasks/tools/install-kubectl/](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* We will be using `kubectl` early on to generate `kubeconfig` files for the controlplane components.
* The environment variable `ARCH` is pre-set during VM deployment according to whether using VirtualBox (`amd64`) or Apple Silicon (`arm64`) to ensure the correct version of this and later software is downloaded for your machine architecture.
  ```bash
  for instance in node01 node02 localhost controlplane01 controlplane02; do
    echo "Installing kubectl on $instance..."
    
    # Use ssh to run commands remotely
    ssh -o StrictHostKeyChecking=no -i ~/.ssh/kubernetes vagrant@${instance} "
      # Download kubectl
      curl -fsSLO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
      
      # Make it executable
      chmod +x kubectl
      
      # Move to system path
      sudo mv kubectl /usr/local/bin/
      
      # Show version
      kubectl version --client
    "
    
    echo "Installation complete on $instance"
    echo "---"
  done
  ```

<br>

---

### **Provisioning a CA and Generating TLS Certificates**

* Set up a Public Key Infrastructure (PKI) using the widely-used `openssl` tool to establish a secure certificate management system.
* Begin by bootstrapping a Certificate Authority (CA) that will serve as the root of trust for the entire cluster.
* Generate TLS certificates for all core Kubernetes components, including:
  - `etcd` - for secure cluster storage
  - `kube-apiserver` - for API endpoint security
  - `kube-controller-manager` - for controller authentication
  - `kube-scheduler` - for scheduler security
  - `kubelet` - for node-level authentication
  - `kube-proxy` - for proxy service security
* While these certificates can be generated on any virtual machine, they must be distributed to the appropriate provisioned VMs after creation.
* For this tutorial, the `jumphost` (administrative client) will serve as the central workstation for generating all certificate files, simplifying management and ensuring consistency.
Here are the key points for setting up environment variables for certificate SANs:

* **Setting Up Environment Variables:**
  * **Query IP addresses from DNS:**
    ```bash
    CONTROL01_IP=$(dig +short controlplane01)
    CONTROL02_IP=$(dig +short controlplane02)
    LOADBALANCER_IP=$(dig +short loadbalancer)
    ```
  * **Compute the Kubernetes API service address:**
    ```bash
    SERVICE_CIDR=10.96.0.0/24
    API_SERVICE=$(echo $SERVICE_CIDR | awk 'BEGIN {FS="."} ; { printf("%s.%s.%s.1", $1, $2, $3) }')
    ```
    This calculates the cluster IP for the Kubernetes API service, which is always the first address (`.1`) in the service CIDR range.
  * **Verify the variables are set correctly:**
    ```bash
    echo $CONTROL01_IP
    echo $CONTROL02_IP
    echo $LOADBALANCER_IP
    echo $SERVICE_CIDR
    echo $API_SERVICE
    ```
    **Expected Output**: The output should display one value per line, similar to:
    ```
    192.168.56.41
    192.168.56.42
    192.168.56.60
    10.96.0.0/24
    10.96.0.1
    ```
  * All these IP addresses must be included as Subject Alternative Names (SANs) in the API server certificate to ensure clients can connect using any of these valid addresses.
  * The `API_SERVICE` address (`10.96.0.1`) is the internal cluster IP where the Kubernetes API service runs, and must also be included as a SAN for internal cluster communication.


### Certificate Authority
* The Certificate Authority (CA) serves as the highest-level entity in the PKI hierarchy and acts as the root of trust for the entire Kubernetes cluster.
* As the top-level authority, the CA is responsible for generating and signing all additional TLS certificates within the infrastructure.
* The CA can produce various types of certificates depending on the requirements:
  * **Server certificates**: For components that act as servers (kube-apiserver, etcd).
  * **Client certificates**: For components that act as clients (kube-scheduler, kube-proxy, kubelet when authenticating to the API server).
  * **Intermediary certificates**: Optional intermediate CAs that can issue certificates on behalf of the root CA.
* By bootstrapping a single Certificate Authority, we establish a chain of trust where all components can validate each other's identities using certificates signed by this common, trusted authority.




#### Creating the CA Certificate

```bash
#Every certificate authority starts with a private key and root certificate. In this section we are going to create a self-signed certificate authority, and while that's all we need for this tutorial, this shouldn't be considered something you would do in a real-world production environment.
#Generate the CA private key:
openssl genrsa -out ca.key 2048
#This creates a 2048-bit RSA private key that will be used to sign all other certificates in the cluster.

#Create the Certificate Signing Request (CSR):
openssl req -new -key ca.key -subj "/CN=KUBERNETES-CA/O=Kubernetes" -out ca.csr
# /CN=KUBERNETES-CA: Sets the Common Name to identify this as the Kubernetes CA
# /O=Kubernetes: Sets the Organization to Kubernetes

#Self-sign the certificate:
openssl x509 -req -in ca.csr -signkey ca.key -CAcreateserial -out ca.crt -days 1000
# Self-signs the CSR using the same private key
# Creates a certificate valid for 1000 days
# -CAcreateserial: Creates a serial number file for tracking
```

#### Resulting Files

| File | Purpose | Security Level |
|------|---------|----------------|
| `ca.crt` | Kubernetes CA certificate (public) | Can be shared widely |
| `ca.key` | Kubernetes CA private key | **MUST BE KEPT SECURE** |

#### Important Notes

* The `ca.crt` file will be copied to many locations throughout the cluster as it's needed by all components to verify certificates signed by this CA
* The `ca.key` is the most sensitive file in the entire PKI infrastructure - it's the key that signs all other certificates
  - In this setup, control plane nodes act as the CA server
  - This key should have strict access controls and permissions
  - If compromised, an attacker could issue valid certificates for any component
* The CA certificate serves as the root of trust for the entire Kubernetes cluster - every component will trust certificates signed by this CA
* All subsequent certificates for etcd, kube-apiserver, kubelet, etc. will be signed using this CA



### Client and Server Certificates

* This section covers generating client and server certificates for each Kubernetes component, plus a special admin user certificate for cluster administration.
* To better understand the role of client certificates with respect to users and groups, see [this informative video](https://youtu.be/I-iVrIWfMl8). Note that all the kubenetes services below are themselves cluster users.


#### **The Admin Client Certificate:** 
* It is used to access the cluster through API server.
* Generate the `admin` client certificate and private key:

  ```bash
  {
    # Generate private key for admin user
    openssl genrsa -out admin.key 2048
    #Creates a 2048-bit RSA private key for the admin user.

    # Generate CSR for admin user. Note the OU.
    openssl req -new -key admin.key -subj "/CN=admin/O=system:masters" -out admin.csr
    # `/CN=admin`: Sets the Common Name to "admin" (the username)
    # `/O=system:masters`: Sets the Organization to "system:masters" (the group)

    # Sign certificate for admin user using CA servers private key
    openssl x509 -req -in admin.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out admin.crt -days 1000
    # Uses the Certificate Authority (CA) we created earlier to sign the admin certificate
    # Creates a certificate valid for 1000 days
  }
  ```

* **Resulting Files**
  | File | Purpose |
  |------|---------|
  | `admin.key` | Admin user's private key (keep secure) |
  | `admin.crt` | Admin user's signed certificate |


* **The `system:masters` group is special:**
  - Members have **unrestricted administrative access** to the entire Kubernetes cluster
  - This group is bound to the `cluster-admin` ClusterRole by default
  - Any user in this group can perform any operation on any resource

* **What this enables:**
  ```bash
  # With these credentials, you can:
  kubectl get nodes
  kubectl create deployments
  kubectl delete pods
  kubectl view secrets
  # ... literally anything in the cluster
  ```

* **Important Notes**
  * The admin certificate is essentially a "master key" to your cluster - protect it carefully
  * The Organization (O) field determines group membership, which maps to RBAC permissions
  * All Kubernetes components (kube-scheduler, kube-controller-manager, etc.) will also get their own certificates as "cluster users"
  * Server certificates for components like kube-apiserver will include SANs (Subject Alternative Names) for all valid connection addresses.


<br>

---

### The Kubernetes API Server Certificate

* The API server certificate is critical because every component (kubelets, scheduler, controller-manager, kubectl users) authenticates to the API server using TLS. The certificate must prove the API server's identity through all possible names and addresses clients might use to reach it.
* These include the different DNS names, and IP addresses such as the controlplane servers IP address, the load balancers IP address, the kube-api service IP address etc. These provide an *identity* for the certificate, which is key in the SSL process for a server to prove who it is.
* The certificate needs to include **every possible way** clients might connect:

  | Entry | Purpose |
  |-------|---------|
  | `DNS.1 = kubernetes` | Internal service name |
  | `DNS.2 = kubernetes.default` | Namespaced service name |
  | `DNS.3 = kubernetes.default.svc` | Service with namespace |
  | `DNS.4 = kubernetes.default.svc.cluster` | With cluster domain |
  | `DNS.5 = kubernetes.default.svc.cluster.local` | Full FQDN |
  | `IP.1 = ${API_SERVICE}` | Cluster IP (10.96.0.1) |
  | `IP.2 = ${CONTROL01_IP}` | First control plane IP |
  | `IP.3 = ${CONTROL02_IP}` | Second control plane IP |
  | `IP.4 = ${LOADBALANCER_IP}` | Load balancer IP |
  | `IP.5 = 127.0.0.1` | Localhost |

* The `openssl` command cannot take alternate names as command line parameter. So we must create a `conf` file for it:
  ```bash
  cat > openssl.cnf <<EOF
  [req]
  req_extensions = v3_req
  distinguished_name = req_distinguished_name
  [req_distinguished_name]
  [v3_req]
  basicConstraints = critical, CA:FALSE
  keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
  extendedKeyUsage = serverAuth
  subjectAltName = @alt_names
  [alt_names]
  DNS.1 = kubernetes
  DNS.2 = kubernetes.default
  DNS.3 = kubernetes.default.svc
  DNS.4 = kubernetes.default.svc.cluster
  DNS.5 = kubernetes.default.svc.cluster.local
  IP.1 = ${API_SERVICE}
  IP.2 = ${CONTROL01_IP}
  IP.3 = ${CONTROL02_IP}
  IP.4 = ${LOADBALANCER_IP}
  IP.5 = 127.0.0.1
  EOF
  ```

* The `openssl.cnf` file defines important certificate properties:
  ```bash
  basicConstraints = critical, CA:FALSE
  # This certificate cannot sign other certificates (not a CA)

  keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
  # What the key can be used for

  extendedKeyUsage = serverAuth
  # This is a server certificate, not a client certificate
  ```

* Certificate Generation Process:
  ```bash
  #Create the private key
  openssl genrsa -out kube-apiserver.key 2048

  #Generate CSR with the config file
  openssl req -new -key kube-apiserver.key \
    -subj "/CN=kube-apiserver/O=Kubernetes" -out kube-apiserver.csr -config openssl.cnf
  # /CN=kube-apiserver: Identifies the component
  # /O=Kubernetes: Group membership

  #Sign with the CA
  openssl x509 -req -in kube-apiserver.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out kube-apiserver.crt \
  -extensions v3_req -extfile openssl.cnf -days 1000
  #The `-extensions v3_req -extfile openssl.cnf` applies the SANs and key usage extensions.
  ```

* Verification
  * After generation, verify the certificate contains all required SANs:
    ```bash
    # Check the Subject Alternative Names
    openssl x509 -in kube-apiserver.crt -text | grep -A 10 "Subject Alternative Name"

    # Output should show:
    # DNS:kubernetes, DNS:kubernetes.default, DNS:kubernetes.default.svc, 
    # DNS:kubernetes.default.svc.cluster, DNS:kubernetes.default.svc.cluster.local, 
    # IP Address:10.96.0.1, IP Address:192.168.56.11, IP Address:192.168.56.12, 
    # IP Address:192.168.56.30, IP Address:127.0.0.1
    ```
  * Why This Matters
    **Without proper SANs, connections fail:**
    ```bash
    # If a kubelet tries to connect via load balancer IP
    # but that IP isn't in SANs:
    kubelet.log: "x509: certificate is valid for 10.96.0.1, 192.168.56.11, not 192.168.56.30"
    ```

* **With proper SANs, all connections work:**
  - ✓ `kubectl` connecting through load balancer
  - ✓ `kubelet` on node01 connecting to controlplane01
  - ✓ `kube-scheduler` connecting to `https://kubernetes.default.svc.cluster.local`
  - ✓ Health checks on `127.0.0.1`

* Resulting Files
  | File | Purpose |
  |------|---------|
  | `kube-apiserver.crt` | API server certificate (public) |
  | `kube-apiserver.key` | API server private key (keep secure) |

<br>

---

### The Controller Manager Client Certificate

* The kube-controller-manager acts as a client that authenticates to the API server to perform its control loop functions (watching resources and reconciling state).
* **Subject fields are critical for RBAC:**
  ```bash
  -subj "/CN=system:kube-controller-manager/O=system:kube-controller-manager"
  ```

  | Field | Value | Purpose |
  |-------|-------|---------|
  | **CN** (Common Name) | `system:kube-controller-manager` | Username that identifies this component |
  | **O** (Organization) | `system:kube-controller-manager` | Group membership for RBAC |

* **Kubernetes uses prefix-based identification:**
  - The `system:` prefix identifies this as a Kubernetes system component
  - The API server automatically grants appropriate permissions to users/groups with this prefix
  - The controller manager needs specific RBAC permissions to function

* **Default RBAC ClusterRoles/ClusterRoleBindings that match these names:**
  ```bash
  # Kubernetes has predefined ClusterRoles for system components
  kubectl describe clusterrole system:kube-controller-manager

  #Name:         system:kube-controller-manager
  #Labels:       kubernetes.io/bootstrapping=rbac-defaults
  #Annotations:  rbac.authorization.kubernetes.io/autoupdate: true
  #PolicyRule:
  #  Resources                                  Non-Resource URLs  Resource Names             Verbs
  #  ---------                                  -----------------  --------------             -----
  #  secrets                                    []                 []                         [create delete get update]
  #  serviceaccounts                            []                 []                         [create get update]
  #  events                                     []                 []                         [create patch update]
  #  events.events.k8s.io                       []                 []                         [create patch update]
  #  serviceaccounts/token                      []                 []                         [create]
  #  tokenreviews.authentication.k8s.io         []                 []                         [create]
  #  subjectaccessreviews.authorization.k8s.io  []                 []                         [create]
  #  leases.coordination.k8s.io                 []                 []                         [create]
  #  leases.coordination.k8s.io                 []                 [kube-controller-manager]  [get update]
  #  configmaps                                 []                 []                         [get]
  #  namespaces                                 []                 []                         [get]
  #  *.*                                        []                 []                         [list watch]

  # This role grants permissions like:
  # - watch endpoints
  # - update node status  
  # - create events
  # ...and all other permissions the controller manager needs

  kubectl describe clusterrolebindings.rbac.authorization.k8s.io system:kube-controller-manager 

  #Name:         system:kube-controller-manager
  #Labels:       kubernetes.io/bootstrapping=rbac-defaults
  #Annotations:  rbac.authorization.kubernetes.io/autoupdate: true
  #Role:
  #  Kind:  ClusterRole
  #  Name:  system:kube-controller-manager
  #Subjects:
  #  Kind  Name                            Namespace
  #  ----  ----                            ---------
  #  User  system:kube-controller-manager  
  ```

* **Generation Process:**
  ```bash
  #Create private key
  openssl genrsa -out kube-controller-manager.key 2048

  # Generate CSR with identifying information
  openssl req -new -key kube-controller-manager.key \
    -subj "/CN=system:kube-controller-manager/O=system:kube-controller-manager" \
    -out kube-controller-manager.csr

  # Sign with the CA
  openssl x509 -req -in kube-controller-manager.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out kube-controller-manager.crt -days 1000
  ```

* **No SANs Required**
  * Unlike the API server certificate, client certificates don't need Subject Alternative Names because:
    - Clients **initiate** connections rather than receiving them
    - The server (API server) validates the client's identity based on CN/O fields
    - No one needs to validate the client's hostname/IP

* Verification
  ```bash
  # Verify the certificate contains the correct subject
  openssl x509 -in kube-controller-manager.crt -text | grep Subject

  # Output:
  # Subject: CN = system:kube-controller-manager, O = system:kube-controller-manager

  # Verify it was signed by our CA
  openssl verify -CAfile ca.crt kube-controller-manager.crt
  # Output: kube-controller-manager.crt: OK
  ```

* How It's Used
  * The controller manager uses this certificate to authenticate to the API server:
    ```bash
    # In kube-controller-manager manifest or config
    spec:
      containers:
      - command:
        - kube-controller-manager
        - --client-ca-file=/etc/kubernetes/pki/ca.crt
        - --tls-cert-file=/etc/kubernetes/pki/kube-controller-manager.crt
        - --tls-private-key-file=/etc/kubernetes/pki/kube-controller-manager.key
    ```

* Resulting Files
  | File | Purpose |
  |------|---------|
  | `kube-controller-manager.key` | Controller manager private key (keep secure) |
  | `kube-controller-manager.crt` | Controller manager certificate (identifies this component) |

* Important Notes
  * The controller manager is a **client** to the API server, so this is a client certificate
  * The naming convention `system:component-name` is crucial for Kubernetes RBAC to work automatically
  * The Organization (`O`) field places it in a group that has the necessary permissions pre-configured by Kubernetes
  * Unlike the API server, no SANs are needed because this certificate is presented **by** the client, not validated **for** the client

<br>

---

### The Kube Proxy Client Certificate
* kube-proxy is the network proxy that runs on each node and maintains network rules. It acts as a client that authenticates to the API server to watch Services and Endpoints, then updates iptables/IPVS rules accordingly.
* **Subject fields for kube-proxy:**
  ```bash
  -subj "/CN=system:kube-proxy/O=system:node-proxier"
  ```

  | Field | Value | Purpose |
  |-------|-------|---------|
  | **CN** (Common Name) | `system:kube-proxy` | Username identifying the kube-proxy component |
  | **O** (Organization) | `system:node-proxier` | Group membership for RBAC |

* **The `system:node-proxier` group is special:**
  - Kubernetes has predefined ClusterRoles and ClusterRoleBindings for this group
  - Members can watch Services and Endpoints resources
  - Members can update node network configuration

* **Default permissions for this group:**
  ```bash
  # Kubernetes automatically grants these permissions to system:node-proxier
  kubectl describe clusterrole system:node-proxier

  # Typically includes:
  # - get/watch/list services
  # - get/watch/list endpoints
  # - get/watch/list endpointslices
  ```

* **Generation Process**
  ```bash
  # Create private key
  openssl genrsa -out kube-proxy.key 2048

  # Generate CSR with identifying information
  openssl req -new -key kube-proxy.key \
    -subj "/CN=system:kube-proxy/O=system:node-proxier" \
    -out kube-proxy.csr

  # Sign with the CA
  openssl x509 -req -in kube-proxy.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out kube-proxy.crt -days 1000
  ```

* **Verification**

  ```bash
  # Verify the certificate subject
  openssl x509 -in kube-proxy.crt -text | grep Subject

  # Output:
  # Subject: CN = system:kube-proxy, O = system:node-proxier

  # Verify against CA
  openssl verify -CAfile ca.crt kube-proxy.crt
  # Output: kube-proxy.crt: OK
  ```

* How kube-proxy Uses This Certificate
  
  **In kube-proxy configuration:**
  ```yaml
  # kube-proxy configmap or manifest
  apiVersion: kubeproxy.config.k8s.io/v1alpha1
  kind: KubeProxyConfiguration
  clientConnection:
    kubeconfig: /var/lib/kube-proxy/kubeconfig
  ```
  **The kubeconfig file references these certs:**
  ```yaml
  # /var/lib/kube-proxy/kubeconfig
  apiVersion: v1
  kind: Config
  clusters:
  - cluster:
      certificate-authority: /var/lib/kubernetes/ca.crt
      server: https://LOADBALANCER:6443
    name: kubernetes
  users:
  - name: kube-proxy
    user:
      client-certificate: /var/lib/kube-proxy/kube-proxy.crt
      client-key: /var/lib/kube-proxy/kube-proxy.key
  ```

* **What kube-proxy Does With These Permissions**
  ```bash
  # kube-proxy watches these resources to configure networking:
  - Services: To know which ClusterIPs need routing rules
  - Endpoints/EndpointSlices: To know which pods back each service
  - Nodes: To know about node changes

  # It then programs the node's network:
  - Creates iptables rules for Service traffic
  - Sets up IPVS rules if using that mode
  - Updates network policies
  ```

* **Resulting Files**
  | File | Purpose |
  |------|---------|
  | `kube-proxy.key` | kube-proxy private key (keep secure) |
  | `kube-proxy.crt` | kube-proxy certificate (identifies this component) |

* **Important Notes**
  * kube-proxy runs on **every node** in the cluster.
  * Each node will need a copy of these files (or its own unique certificate).
  * The certificate identifies the component type, not the specific node instance.
  * The group `system:node-proxier` is distinct from `system:nodes` (which is for kubelet).
  * Like other client certificates, no SANs are needed since this is a client certificate.

<br>

---

### The Scheduler Client Certificate
* The kube-scheduler is responsible for assigning newly created pods to appropriate nodes. It acts as a client that authenticates to the API server to watch for unscheduled pods, get node information, and update pod bindings.

* **Subject fields for kube-scheduler:**
  ```bash
  -subj "/CN=system:kube-scheduler/O=system:kube-scheduler"
  ```

  | Field | Value | Purpose |
  |-------|-------|---------|
  | **CN** (Common Name) | `system:kube-scheduler` | Username identifying the scheduler component |
  | **O** (Organization) | `system:kube-scheduler` | Group membership for RBAC |

* **The `system:kube-scheduler` identity is pre-wired in Kubernetes:**
  - Kubernetes automatically creates ClusterRoles and bindings for this system component
  - The scheduler needs specific permissions to:
    - Watch pods (especially those with `nodeName` empty)
    - Get node details (resources, labels, taints)
    - Update pod bindings (assign pods to nodes)
    - Watch persistent volumes and claims (for pod scheduling decisions)

* **Default permissions via automatic RBAC:**
  ```bash
  # Kubernetes grants the scheduler permissions like:
  kubectl describe clusterrole system:kube-scheduler

  # Typical permissions include:
  # - get/watch/list pods
  # - get/watch/list nodes
  # - create/update pod bindings
  # - get/watch/list persistentvolumes
  # - get/watch/list persistentvolumeclaims
  ```

* **Generation Process**
  ```bash
  # Create private key
  openssl genrsa -out kube-scheduler.key 2048

  # Generate CSR with identifying information
  openssl req -new -key kube-scheduler.key \
    -subj "/CN=system:kube-scheduler/O=system:kube-scheduler" \
    -out kube-scheduler.csr

  # Sign with the CA
  openssl x509 -req -in kube-scheduler.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out kube-scheduler.crt -days 1000
  ```

* **Verification**
  ```bash
  # Verify the certificate subject
  openssl x509 -in kube-scheduler.crt -text | grep Subject

  # Output:
  # Subject: CN = system:kube-scheduler, O = system:kube-scheduler

  # Verify against CA
  openssl verify -CAfile ca.crt kube-scheduler.crt
  # Output: kube-scheduler.crt: OK
  ```

* **How the Scheduler Uses This Certificate**

  **In kube-scheduler configuration:**
  ```yaml
  # /etc/kubernetes/manifests/kube-scheduler.yaml or config file
  apiVersion: kubescheduler.config.k8s.io/v1
  kind: KubeSchedulerConfiguration
  clientConnection:
    kubeconfig: /etc/kubernetes/scheduler/kubeconfig
  ```

  **The kubeconfig file references these certs:**
  ```yaml
  # /etc/kubernetes/scheduler/kubeconfig
  apiVersion: v1
  kind: Config
  clusters:
  - cluster:
      certificate-authority: /etc/kubernetes/pki/ca.crt
      server: https://127.0.0.1:6443  # or load balancer
    name: kubernetes
  users:
  - name: system:kube-scheduler
    user:
      client-certificate: /etc/kubernetes/pki/kube-scheduler.crt
      client-key: /etc/kubernetes/pki/kube-scheduler.key
  ```

* **What the Scheduler Does With These Permissions**
  ```bash
  # The scheduler constantly watches for:
  1. New pods with empty nodeName field
    kubectl get pods --all-namespaces --field-selector spec.nodeName=

  2. Node resources and availability
    kubectl get nodes -o wide

  3. Pod resource requests vs node allocatable resources

  4. Node labels, taints, and tolerations

  5. Persistent volume claims that need binding

  # When it finds an unscheduled pod, it:
  1. Filters nodes (finds viable nodes)
  2. Scores nodes (ranks the viable nodes)
  3. Binds the pod to the highest scoring node
    kubectl bind pod-to-node
  ```

* **Resulting Files**
  | File | Purpose |
  |------|---------|
  | `kube-scheduler.key` | Scheduler private key (keep secure) |
  | `kube-scheduler.crt` | Scheduler certificate (identifies this component) |

* **Important Notes**
  * The scheduler is a **control plane component** that runs on master nodes
  * Like other client certificates, no SANs are needed (it initiates connections, doesn't receive them)
  * The naming convention `system:kube-scheduler` is critical for Kubernetes to recognize it as a system component
  * The Organization (`O`) field matches the Common Name, placing it in its own group
  * This certificate is used **only** by the scheduler to authenticate to the API server

<br>

---

### The API Server Kubelet Client Certificate

* This certificate enables the **API server to act as a client** when connecting to kubelets on worker nodes. * The API server needs to fetch information from kubelets (like logs, exec into pods, port-forwarding) and must authenticate itself to each kubelet.
* Unlike the main API server certificate (which is a **server certificate** presented TO clients), this is a **client certificate** that the API server presents WHEN connecting to kubelets.

* **Special configuration file:**
  ```bash
  cat > openssl-kubelet.cnf <<EOF
  [req]
  req_extensions = v3_req
  distinguished_name = req_distinguished_name
  [req_distinguished_name]
  [v3_req]
  basicConstraints = critical, CA:FALSE
  keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
  extendedKeyUsage = clientAuth
  EOF
  ```

* **Key extensions explained:**
  | Extension | Value | Purpose |
  |-----------|-------|---------|
  | `basicConstraints` | `CA:FALSE` | This is not a CA certificate |
  | `keyUsage` | `digitalSignature, keyEncipherment` | What the key can do |
  | `extendedKeyUsage` | `clientAuth` | **This is a client certificate** (not serverAuth) |

* **Subject fields:**
  ```bash
  -subj "/CN=kube-apiserver-kubelet-client/O=system:masters"
  ```
  | Field | Value | Purpose |
  |-------|-------|---------|
  | **CN** | `kube-apiserver-kubelet-client` | Identifies this as the API server's client cert for kubelets |
  | **O** | `system:masters` | Places it in the **master** group with high privileges |

* **Why `system:masters`**?
  * Kubelets are configured with authorization modes that typically include **Node authorization** and **RBAC**. The `system:masters` group gives this certificate:
    - Broad access to kubelet's API endpoints
    - Ability to request pod logs, exec into containers, port-forward
    - Access to node health information
  * This is the **same group** as the admin user, indicating the trust level needed for the API server to access kubelet resources.

* **Generation Process**
  ```bash
  # Create private key
  openssl genrsa -out apiserver-kubelet-client.key 2048

  # Generate CSR with client extensions
  openssl req -new -key apiserver-kubelet-client.key \
    -subj "/CN=kube-apiserver-kubelet-client/O=system:masters" \
    -out apiserver-kubelet-client.csr -config openssl-kubelet.cnf

  # Sign with the CA
  openssl x509 -req -in apiserver-kubelet-client.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out apiserver-kubelet-client.crt \
    -extensions v3_req -extfile openssl-kubelet.cnf -days 1000
  ```

* **Verification**

  ```bash
  # Verify it's a client certificate (not server)
  openssl x509 -in apiserver-kubelet-client.crt -text | grep -A 1 "X509v3 Extended Key Usage"

  # Output:
  # X509v3 Extended Key Usage:
  #   TLS Web Client Authentication

  # Verify subject
  openssl x509 -in apiserver-kubelet-client.crt -text | grep Subject
  # Output: Subject: CN = kube-apiserver-kubelet-client, O = system:masters

  # Verify against CA
  openssl verify -CAfile ca.crt apiserver-kubelet-client.crt
  ```

* How It's Used

  **In kube-apiserver configuration:**
  ```yaml
  # /etc/kubernetes/manifests/kube-apiserver.yaml
  spec:
    containers:
    - command:
      - kube-apiserver
      - --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
      - --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key
  ```

  **When API server connects to a kubelet:**
  ![alt text](image.png)

* **What This Enables** With this certificate, the API server can:
  ```bash
  # View pod logs (kubelet serves logs)
  kubectl logs pod-name

  # Execute commands in containers
  kubectl exec -it pod-name -- /bin/sh

  # Port forward to pods
  kubectl port-forward pod-name 8080:80

  # Get node status and health
  kubectl get nodes
  kubectl describe node node01
  ```

* **Resulting Files**
  | File | Purpose |
  |------|---------|
  | `apiserver-kubelet-client.key` | Private key (keep secure) |
  | `apiserver-kubelet-client.crt` | Client certificate for API server → kubelet connections |

* **Important Notes**
  * This is a **client certificate** despite being used by the API server
  * The `extendedKeyUsage = clientAuth` is critical - without it, kubelets would reject the connection
  * Being in `system:masters` group gives it full access to all kubelet operations
  * Each kubelet is configured with the CA certificate to validate this client cert
  * This certificate is different from the main API server certificate (which has `serverAuth`)

<br>

---

### The ETCD Server Certificate

* etcd is the distributed key-value store that holds the entire cluster state. 
* The etcd server certificate is presented to clients (API server, etcd clients) when they connect to etcd. 
* Since etcd runs as a cluster across multiple control plane nodes, the certificate must identify all possible addresses where etcd can be reached.

* Like the API server, etcd is a **server** that clients connect to. Clients need to validate that they're connecting to the legitimate etcd server. The certificate must include all valid etcd endpoints.

* Certificate Configuration File:

  ```bash
  cat > openssl-etcd.cnf <<EOF
  [req]
  req_extensions = v3_req
  distinguished_name = req_distinguished_name
  [req_distinguished_name]
  [ v3_req ]
  basicConstraints = CA:FALSE
  keyUsage = nonRepudiation, digitalSignature, keyEncipherment
  subjectAltName = @alt_names
  [alt_names]
  IP.1 = ${CONTROL01_IP}
  IP.2 = ${CONTROL02_IP}
  IP.3 = 127.0.0.1
  EOF
  ```

  **SANs included:**
  | Entry | Purpose |
  |-------|---------|
  | `IP.1 = ${CONTROL01}` | etcd instance on first control plane |
  | `IP.2 = ${CONTROL02}` | etcd instance on second control plane |
  | `IP.3 = 127.0.0.1` | Localhost access (for etcdctl local operations) |

* **Each etcd member needs to be reachable by others:**
  - etcd cluster members communicate with each other for consensus (Raft)
  - The API server connects to etcd (usually via localhost or load balancer)
  - etcd clients (like etcdctl) need to connect

* **If SANs are missing:**
  ```bash
  # API server would fail to connect:
  etcd.log: "x509: certificate is valid for 192.168.56.41, 127.0.0.1, not 192.168.56.42"
  # When controlplane02 tries to join the etcd cluster
  ```

* Certificate Generation
  ```bash
  # Create private key
  openssl genrsa -out etcd-server.key 2048

  # Generate CSR with SANs
  openssl req -new -key etcd-server.key \
    -subj "/CN=etcd-server/O=Kubernetes" \
    -out etcd-server.csr -config openssl-etcd.cnf

  # Sign with CA
  openssl x509 -req -in etcd-server.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out etcd-server.crt \
    -extensions v3_req -extfile openssl-etcd.cnf -days 1000
  ```

* Subject Fields Explained
  ```bash
  -subj "/CN=etcd-server/O=Kubernetes"
  ```

  | Field | Value | Purpose |
  |-------|-------|---------|
  | **CN** | `etcd-server` | Identifies this as the etcd server certificate |
  | **O** | `Kubernetes` | Organizational grouping |

* Verification
  ```bash
  # Check all SANs are present
  openssl x509 -in etcd-server.crt -text | grep -A 5 "Subject Alternative Name"

  # Output should show:
  # X509v3 Subject Alternative Name:
  #   IP Address:192.168.56.41, IP Address:192.168.56.42, IP Address:127.0.0.1

  # Verify subject
  openssl x509 -in etcd-server.crt -text | grep Subject
  # Output: Subject: CN = etcd-server, O = Kubernetes

  # Verify against CA
  openssl verify -CAfile ca.crt etcd-server.crt
  ```

* How ETCD Uses This Certificate

  **In etcd configuration (on each control plane node):**
  ```yaml
  # /etc/etcd/etcd.conf or etcd manifest
  ETCD_CERT_FILE="/etc/etcd/pki/etcd-server.crt"
  ETCD_KEY_FILE="/etc/etcd/pki/etcd-server.key"
  ETCD_TRUSTED_CA_FILE="/etc/etcd/pki/ca.crt"
  ETCD_CLIENT_CERT_AUTH="true"
  ETCD_PEER_CERT_FILE="/etc/etcd/pki/etcd-server.crt"  # Same cert for peer comms
  ETCD_PEER_KEY_FILE="/etc/etcd/pki/etcd-server.key"
  ETCD_PEER_TRUSTED_CA_FILE="/etc/etcd/pki/ca.crt"
  ```

  **Listen addresses:**
  ```yaml
  ETCD_LISTEN_CLIENT_URLS="https://192.168.56.41:2379,https://127.0.0.1:2379"
  ETCD_LISTEN_PEER_URLS="https://192.168.56.41:2380"
  ETCD_ADVERTISE_CLIENT_URLS="https://192.168.56.41:2379"
  ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.56.41:2380"
  ```

* **Cluster Communication Flow**

  ![alt text](image-1.png)

* **Resulting Files**

  | File | Purpose |
  |------|---------|
  | `etcd-server.key` | etcd private key (keep secure) |
  | `etcd-server.crt` | etcd server certificate (must be copied to all etcd members) |

* **Important Notes**
  * This is a **server certificate** (though etcd also uses it for peer communication)
  * The same certificate can be used on all etcd members since it contains all their IPs
  * etcd also needs client certificates for mutual TLS (mTLS) - this is just the server side
  * Each etcd member validates peer connections using the CA certificate
  * The certificate must include ALL etcd member IPs for proper cluster formation
  * If adding more control plane nodes later, you'd need to regenerate this certificate with additional SANs

<br>

---

### The Service Account Key Pair

* The `service-account.crt` and `service-account.key` files you are creating are used by the Kubernetes Controller Manager to **generate and digitally sign** service account tokens as described in the [managing service accounts](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/) documentation. These tokens are how pods authenticate to the Kubernetes API server.

* **Pod Creation**: When a pod is created (often with a default or specified service account), the kubelet on that node requests a time-bound token from the API server using the **TokenRequest API**.
  ```bash
  # Behind the scenes: Kubelet calls TokenRequest API
  # This happens automatically, no manual intervention
  POST /api/v1/namespaces/default/serviceaccounts/default/token
  ```

* **Token Signing**: The API server (via the Controller Manager) uses the private key (`service-account.key`) to sign this token, creating a JSON Web Token (JWT). This proves the token's authenticity.
  - API server receives the request
  - Controller Manager generates a JWT (JSON Web Token)
  - Signs it with `service-account.key`
  - Token includes claims:
    ```json
    {
      "aud": [
        "https://kubernetes.default.svc.cluster.local"
      ],
      "exp": 1804167941,
      "iat": 1772631941,
      "iss": "https://kubernetes.default.svc.cluster.local",
      "jti": "85eb8f3c-17bd-48df-9522-58855a30304f",
      "kubernetes.io": {
        "namespace": "default",
        "node": {
          "name": "node01",
          "uid": "a235692f-8fa3-4fd6-b5b3-eac4e5b7598f"
        },
        "pod": {
          "name": "nginx",
          "uid": "7abfd688-5480-47b2-bd52-8849a74ef2c0"
        },
        "serviceaccount": {
          "name": "default",
          "uid": "8be809c8-a91f-45a5-b728-a78b32e87dfe"
        },
        "warnafter": 1772635548
      },
      "nbf": 1772631941,
      "sub": "system:serviceaccount:default:default"
    }
    ```

* **Token Mounting**: 
  * Signed token is returned to kubelet
  * The signed token is mounted into the pod via a **projected volume**.
  * Kubelet mounts it into the pod at: `/var/run/secrets/kubernetes.io/serviceaccount/token`
  * Also mounts CA certificate at: `/var/run/secrets/kubernetes.io/serviceaccount/ca.crt` (To verify the API server's identity).
  * Its own namespace from the Downward API.

* **Authentication**: When a process inside the pod wants to talk to the API server, it presents this JWT. The API server uses the public key (`service-account.crt`) to **verify the token's signature**. If valid, it extracts the claims (like the pod's name, namespace, and service account) to identify and authorize the request.
  ```bash
  # Inside the pod, applications can use the token
  curl -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    https://kubernetes.default.svc.cluster.local/api/v1/namespaces/default/pods
  ```


* **Time-Bound & Automatic Refresh**: Tokens have a short lifespan (default 1 hour) and are automatically refreshed by the kubelet before expiry, limiting the damage if a token is compromised.
* **Object-Bound**: Tokens are cryptographically bound to the specific pod that requested them (including the Pod's UID and the Node's name). This allows the API server to reject tokens from pods that no longer exist.
* **Manual Secrets (Legacy)**: You can still manually create long-lived service account tokens using Secrets, but the documentation **strongly recommends using the TokenRequest mechanism** for short-lived, bound tokens for better security.

*   **You are creating a key pair**, not an actual token. This key pair is a critical piece of your **PKI infrastructure**, just like the certificates for `etcd` or `kube-apiserver`.

*   The Controller Manager will hold the **private key (`service-account.key`)** for signing.

*   The API server will use the **public certificate (`service-account.crt`)** to verify tokens presented by pods.

*   The keys you generate now will be referenced in the Controller Manager and API server manifests, enabling the entire service account authentication flow for your cluster.

* Generate the `service-account` certificate and private key:
  ```bash
  {
    # Generate private key for service account token signing
    openssl genrsa -out service-account.key 2048

    # Generate CSR 
    openssl req -new -key service-account.key \
      -subj "/CN=service-accounts/O=Kubernetes" -out service-account.csr

    # Sign with CA to create certificate
    openssl x509 -req -in service-account.csr \
      -CA ca.crt -CAkey ca.key -CAcreateserial -out service-account.crt -days 1000
  }
  ```

* **Results:**
  - `service-account.key` - **Private key** (keep secure, used by Controller Manager)
  - `service-account.crt` - **Public certificate** (used by API Server for verification)

* **Verification**
  ```bash
  # Verify the service account certificate
  openssl x509 -in service-account.crt -text | grep -E "Subject|Not"

  # Output:
  # Subject: CN = service-accounts, O = Kubernetes
  # Not Before: Mar  4 12:00:00 2026 GMT
  # Not After : Nov 28 12:00:00 2028 GMT

  # Check it was signed by our CA
  openssl verify -CAfile ca.crt service-account.crt
  # Output: service-account.crt: OK
  ```

* **Where These Files Are Used**

  **In Controller Manager manifest:**
  ```yaml
  # /etc/kubernetes/manifests/kube-controller-manager.yaml
  spec:
    containers:
    - command:
      - kube-controller-manager
      - --service-account-private-key-file=/etc/kubernetes/pki/service-account.key
      # ... other flags
  ```

  **In API Server manifest:**
  ```yaml
  # /etc/kubernetes/manifests/kube-apiserver.yaml
  spec:
    containers:
    - command:
      - kube-apiserver
      - --service-account-key-file=/etc/kubernetes/pki/service-account.crt
      - --service-account-signing-key-file=/etc/kubernetes/pki/service-account.key
      - --service-account-issuer=https://kubernetes.default.svc.cluster.local
      # ... other flags
  ```

* **Security Considerations**

  - **`service-account.key`** is extremely sensitive - if compromised, attackers could forge valid service account tokens.
  - Unlike TLS certificates, these tokens are **short-lived** (1 hour default) to limit damage from leaks.
  - Tokens are **bound to specific pods** - they can't be used by other pods even if stolen.
  - The Controller Manager holds the private key, while the API Server only needs the public certificate for verification.
  - In production, consider using **external key management systems** (HSM, KMS) for the service account key.

  This key pair enables the entire pod identity system in Kubernetes, allowing workloads to securely authenticate to the API server without hardcoded credentials.


* **Token Verification Flow**
  When a pod's token is presented to the API server:

  ```bash
  # API server verifies the token signature
  1. Extract token from Authorization header
  2. Use service-account.crt to verify signature
  3. Check token expiration (exp claim)
  4. Validate bound object claims (pod UID, etc.)
  5. Extract service account and namespace
  6. Apply RBAC permissions based on service account
  ```

<br>

---

### **Verify All Certificates**
  Run the verification script to ensure all certificates were generated correctly:

  ```bash
  # From the root directory
  ./cert_verify.sh
  # Select option 1 when prompted
  ```

* **The script verifies:**
  - ✓ CA certificate and key
  - ✓ kube-apiserver certificate and key
  - ✓ kube-controller-manager certificate and key  
  - ✓ kube-scheduler certificate and key
  - ✓ service-account certificate and key
  - ✓ apiserver-kubelet-client certificate and key
  - ✓ etcd-server certificate and key
  - ✓ admin certificate and key
  - ✓ kube-proxy certificate and 
  
<br>

---

### **Distribute Certificates to Nodes**
Copy certificates to their respective instances:
```bash
{
for instance in controlplane01 controlplane02; do
  scp -o StrictHostKeyChecking=no -i ~/.ssh/kubernetes ca.crt ca.key kube-apiserver.key kube-apiserver.crt \
    apiserver-kubelet-client.crt apiserver-kubelet-client.key \
    service-account.key service-account.crt \
    etcd-server.key etcd-server.crt \
    kube-controller-manager.key kube-controller-manager.crt \
    kube-scheduler.key kube-scheduler.crt \
    ${instance}:~/
done

for instance in node01 node02 ; do
  scp -o StrictHostKeyChecking=no -i ~/.ssh/kubernetes ca.crt kube-proxy.crt kube-proxy.key ${instance}:~/
done
}
```

<br>

---

### **Manual Verification on Nodes**
SSH into a control plane node and verify:
```bash
# On controlplane02
ssh controlplane02
./cert_verify.sh
# Select option 1
```

<br>

---

### **Certificate Overview**

| Component | Common Name (CN) | Organization (O) | Purpose |
|-----------|-----------------|------------------|---------|
| **Admin** | `admin` | `system:masters` | Full administrative access via kubectl |
| **Controller Manager** | `system:kube-controller-manager` | `system:kube-controller-manager` | Runs controllers (deployments, replicasets, etc.) |
| **Scheduler** | `system:kube-scheduler` | `system:kube-scheduler` | Assigns pods to nodes |
| **kube-proxy** | `system:kube-proxy` | `system:node-proxier` | Manages network rules on nodes |
| **kubelet** | `system:node:<node-name>` | `system:nodes` | Node-level container runtime operations |
| **API Server** | `kube-apiserver` | `Kubernetes` | Serves Kubernetes API (server cert) |
| **API Server Kubelet Client** | `kube-apiserver-kubelet-client` | `system:masters` | API server → kubelet connections |
| **ETCD Server** | `etcd-server` | `Kubernetes` | Serves etcd cluster API (server cert) |
| **Service Account** | `service-accounts` | `Kubernetes` | Signs pod JWT tokens (not for TLS) |

<br>

---

### **Key Distribution Summary**

| Node Type | Certificates Required |
|-----------|----------------------|
| **controlplane01/02** | `ca.crt`, `kube-apiserver.crt/.key`, `kube-controller-manager.crt/.key`, `kube-scheduler.crt/.key`, `service-account.crt/.key`, `apiserver-kubelet-client.crt/.key`, `etcd-server.crt/.key`, `admin.crt/.key`, `kube-proxy.crt/.key` |
| **worker nodes (node01)** | `ca.crt`, `kube-proxy.crt/.key`, `kubelet certificates` (generated later) |


<br>

<br>
<br>

---

### **Generating Kubernetes Configuration Files for Authentication**

* [Kubernetes configuration files](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/), also known as "kubeconfigs", which enable Kubernetes clients to locate and authenticate to the Kubernetes API Servers.
* It is good practice to use file paths to certificates in kubeconfigs that will be used by the services(kubelet, kube-proxy, controller-manager, scheduler). When certificates are updated, it is not necessary to regenerate the config files, as you would have to if the certificate data was embedded. 
* User configs, like `admin.kubeconfig` will have the certificate info embedded within them.
* Each kubeconfig file needs to know which Kubernetes API Server to connect to. Since this is a high-availability cluster with multiple control plane nodes, we use a load balancer as the single entry point.
* Control plane components(kube-controller-manager, kube-scheduler) use localhost to avoid network hops and maintain availability even if load balancer is down.

  ```bash
  LOADBALANCER_IP=$(dig +short loadbalancer)
  echo $LOADBALANCER_IP
  ```

#### The kube-proxy Kubernetes Configuration File

* Generate a kubeconfig file for the `kube-proxy` service:

  ```bash
  {
    kubectl config set-cluster kubernetes-the-hard-way \
      --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
      --server=https://${LOADBALANCER_IP}:6443 \
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

#### The kube-controller-manager Kubernetes Configuration File
* Generate a kubeconfig file for the `kube-controller-manager` service:

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


#### The kube-scheduler Kubernetes Configuration File
* Generate a kubeconfig file for the `kube-scheduler` service:
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

#### The admin Kubernetes Configuration File
* Generate a kubeconfig file for the `admin` user:
  ```bash
  {
    kubectl config set-cluster kubernetes-the-hard-way \
      --certificate-authority=ca.crt \
      --embed-certs=true \
      --server=https://${LOADBALANCER_IP}:6443 \
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

<br>

---

### D**istribute the Kubernetes Configuration Files**

Copy the appropriate `kube-proxy` kubeconfig files to each worker instance:

```bash
for instance in node01 node02; do
  echo "=== Copying kube-proxy config to ${instance} ==="
  
  # Copy to home directory first
  scp -o StrictHostKeyChecking=no -i ~/.ssh/kubernetes kube-proxy.kubeconfig ${instance}:~/
  
  # Move to proper location and set permissions
  ssh -o StrictHostKeyChecking=no -i ~/.ssh/kubernetes ${instance} "
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
  scp -o StrictHostKeyChecking=no -i ~/.ssh/kubernetes \
    admin.kubeconfig \
    kube-controller-manager.kubeconfig \
    kube-scheduler.kubeconfig \
    ${instance}:~/
  
  # Move to proper locations and set permissions
  ssh -o StrictHostKeyChecking=no ${instance} -i ~/.ssh/kubernetes "
    # Admin kubeconfig (for kubectl)
    sudo mkdir -p /root/.kube
    sudo cp ~/admin.kubeconfig /root/.kube/config
    sudo chown root:root /root/.kube/config
    sudo chmod 600 /root/.kube/config

    # Admin kubeconfig (for kubectl)
    sudo mkdir -p ~/.kube
    sudo cp ~/admin.kubeconfig ~/.kube/config
    sudo chown vagrant:vagrant ~/.kube/config
    sudo chmod 600 ~/.kube/config
    
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
  ssh -o StrictHostKeyChecking=no -i ~/.ssh/kubernetes ${instance} "sudo ls -la /var/lib/kube-proxy/"
done

# Verify control plane nodes
for instance in controlplane01 controlplane02; do
  echo "=== ${instance} configs ==="
  ssh -o StrictHostKeyChecking=no -i ~/.ssh/kubernetes ${instance} "
    sudo ls -la /root/.kube/
    sudo ls -la /var/lib/kubernetes/
  "
done
```

<br>

---

### **Generating the Data Encryption Config and Key**
* Kubernetes stores a variety of data including cluster state, application configurations, and secrets. Kubernetes supports the ability to [encrypt](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data) cluster data at rest, that is, the data stored within `etcd`.

* We will generate an encryption key and an [encryption config](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#understanding-the-encryption-at-rest-configuration) suitable for encrypting Kubernetes Secrets.

* **The Encryption Key:**

  Generate an encryption key. This is simply 32 bytes of random data, which we base64 encode:
  ```bash
  ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
  ```

* The Encryption Config File
  
  Create the `encryption-config.yaml` encryption config file:
  ```bash
  cat > encryption-config.yaml <<EOF
  kind: EncryptionConfig
  apiVersion: v1
  resources:
    - resources:
        - secrets
      providers:
        - aescbc:
            keys:
              - name: key1
                secret: ${ENCRYPTION_KEY}
        - identity: {}
  EOF
  ```

* Copy the `encryption-config.yaml` encryption config file to each controller instance:

  ```bash
  for instance in controlplane01 controlplane02; do
    scp -o StrictHostKeyChecking=no -i ~/.ssh/kubernetes encryption-config.yaml ${instance}:~/
  done
  ```

* Move `encryption-config.yaml` encryption config file to appropriate directory.

  ```bash
  for instance in controlplane01 controlplane02; do
    ssh -o StrictHostKeyChecking=no -i ~/.ssh/kubernetes ${instance} sudo mkdir -p /var/lib/kubernetes/
    ssh -o StrictHostKeyChecking=no -i ~/.ssh/kubernetes ${instance} sudo mv encryption-config.yaml /var/lib/kubernetes/
    ssh -o StrictHostKeyChecking=no -i ~/.ssh/kubernetes ${instance} sudo ls /var/lib/kubernetes/
  done
  ```

Reference: https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#encrypting-your-data


<br>

---

### Bootstrapping the etcd Cluster
* Kubernetes components are stateless and store cluster state in [etcd](https://etcd.io/). 
* In this lab you will bootstrap a two node etcd cluster and configure it for high availability and secure remote access.
* The commands in this lab must be run on each controller instance: `controlplane01`, and `controlplane02`. Login to each of these using an SSH terminal.

* Download and Install the etcd Binaries:
  
  Official etcd release binaries --> [etcd](https://github.com/etcd-io/etcd) GitHub project:
  ```bash
  {
    export ARCH="amd64"
    ETCD_VERSION="v3.5.9"
    DOWNLOAD_URL="https://storage.googleapis.com/etcd"

    # Clean up old files
    rm -f "/tmp/etcd-${ETCD_VERSION}-linux-${ARCH}.tar.gz"
    rm -rf "/tmp/etcd-download-test" && mkdir -p "/tmp/etcd-download-test"

    # Download with correct quoting
    curl -L "${DOWNLOAD_URL}/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-${ARCH}.tar.gz" \
      -o "/tmp/etcd-${ETCD_VERSION}-linux-${ARCH}.tar.gz"

    # Check if download was successful
    if [ ! -f "/tmp/etcd-${ETCD_VERSION}-linux-${ARCH}.tar.gz" ]; then
      echo "Download failed!"
      exit 1
    fi

    # Extract
    tar xzvf "/tmp/etcd-${ETCD_VERSION}-linux-${ARCH}.tar.gz" \
      -C "/tmp/etcd-download-test" \
      --strip-components=1 \
      --no-same-owner

    # Clean up tar file
    rm -f "/tmp/etcd-${ETCD_VERSION}-linux-${ARCH}.tar.gz"

    # Install binaries
    sudo mv /tmp/etcd-download-test/etcd* /usr/local/bin/

    # Verify architecture and installation
    echo "=== Installation Verification ==="
    file /usr/local/bin/etcd
    etcd --version
    etcdctl version
    etcdutl version
  }
  ```
* Configure the etcd Server
  * Copy and secure certificates. 
  * Note that we place `ca.crt` in our main PKI directory and link it from etcd to not have multiple copies of the cert lying around.

    ```bash
    {
      # Create required directories
      sudo mkdir -p /etc/etcd /var/lib/etcd /var/lib/kubernetes/pki
      
      # Copy etcd certificates
      sudo cp etcd-server.key etcd-server.crt /etc/etcd/
      
      # Copy CA certificate to shared PKI location
      sudo cp ca.crt /var/lib/kubernetes/pki/
      
      # Set secure ownership and permissions
      sudo chown root:root /etc/etcd/*
      sudo chmod 600 /etc/etcd/*
      sudo chown root:root /var/lib/kubernetes/pki/*
      sudo chmod 600 /var/lib/kubernetes/pki/*
      
      # Create symbolic link to avoid duplicate certificates
      sudo ln -s /var/lib/kubernetes/pki/ca.crt /etc/etcd/ca.crt
    }
    ```

* Each etcd member needs to know its own IP address (for serving client requests) and the IPs of other cluster members (for peer communication). Run these commands on each control plane node:
  ```bash
  # Get IP addresses of both etcd cluster members (control plane nodes)
  CONTROL01_IP=$(dig +short controlplane01)
  CONTROL02_IP=$(dig +short controlplane02)

  # Verify all IPs are correctly retrieved
  echo "controlplane01 IP: $CONTROL01_IP"
  echo "controlplane02 IP: $CONTROL02_IP"
  ```

* Each etcd member must have a unique name within an etcd cluster. Set the etcd name to match the hostname of the current compute instance:

  ```bash
  ETCD_NAME=$(hostname -s)
  ```

* Create the `etcd.service` systemd unit file:

  ```bash
  cat <<EOF | sudo tee /etc/systemd/system/etcd.service
  [Unit]
  Description=etcd
  Documentation=https://github.com/coreos

  [Service]
  ExecStart=/usr/local/bin/etcd \\
    --name ${ETCD_NAME} \\
    --cert-file=/etc/etcd/etcd-server.crt \\
    --key-file=/etc/etcd/etcd-server.key \\
    --peer-cert-file=/etc/etcd/etcd-server.crt \\
    --peer-key-file=/etc/etcd/etcd-server.key \\
    --trusted-ca-file=/etc/etcd/ca.crt \\
    --peer-trusted-ca-file=/etc/etcd/ca.crt \\
    --peer-client-cert-auth \\
    --client-cert-auth \\
    --initial-advertise-peer-urls https://${PRIMARY_IP}:2380 \\
    --listen-peer-urls https://${PRIMARY_IP}:2380 \\
    --listen-client-urls https://${PRIMARY_IP}:2379,https://127.0.0.1:2379 \\
    --advertise-client-urls https://${PRIMARY_IP}:2379 \\
    --initial-cluster-token etcd-cluster-0 \\
    --initial-cluster controlplane01=https://${CONTROL01_IP}:2380,controlplane02=https://${CONTROL02_IP}:2380 \\
    --initial-cluster-state new \\
    --data-dir=/var/lib/etcd
  Restart=on-failure
  RestartSec=5

  [Install]
  WantedBy=multi-user.target
  EOF
  ```

* Start the etcd Server

  ```bash
  {
    sudo systemctl daemon-reload
    sudo systemctl enable etcd
    sudo systemctl start etcd
    sudo systemctl status etcd
  }
  ```

* After running the above commands on both controlplane nodes, run the following on either or both of `controlplane01` and `controlplane02`

  ```bash
  sudo ETCDCTL_API=3 etcdctl member list \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/etcd/ca.crt \
    --cert=/etc/etcd/etcd-server.crt \
    --key=/etc/etcd/etcd-server.key --write-out=table

  sudo ETCDCTL_API=3 etcdctl endpoint status \
    --endpoints=https://127.0.0.1:2379,https://192.168.56.42:2379 \
    --cacert=/etc/etcd/ca.crt \
    --cert=/etc/etcd/etcd-server.crt \
    --key=/etc/etcd/etcd-server.key --write-out=table
  ```
  Output will be similar to this

  ```bash
  45bf9ccad8d8900a, started, controlplane02, https://192.168.56.12:2380, https://192.168.56.12:2379
  54a5796a6803f252, started, controlplane01, https://192.168.56.11:2380, https://192.168.56.11:2379
  ```

Reference: https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#starting-etcd-clusters

<br>

---

### Bootstrapping the Kubernetes Control Plane

* We will bootstrap the Kubernetes control plane across 2 compute instances and configure it for high availability. 
* Also create an external load balancer that exposes the Kubernetes API Servers to remote clients.
* The following components will be installed on each node: Kubernetes API Server, Scheduler, and Controller Manager.
* Note that in a production-ready cluster it is recommended to have an odd number of controlplane nodes as for multi-node services like etcd, leader election and quorum work better. See lecture on this ([KodeKloud](https://kodekloud.com/topic/etcd-in-ha/), [Udemy](https://www.udemy.com/course/certified-kubernetes-administrator-with-practice-tests/learn/lecture/14296192#overview)). We're only using two here to save on RAM on your workstation.


#### First the load balancer must be configured:

* In this section you will provision an external network load balancer to front the Kubernetes API Servers.
* Static IP address will be attached to the resulting load balancer.
* A NLB operates at [layer 4](https://en.wikipedia.org/wiki/OSI_model#Layer_4:_Transport_layer) (TCP) meaning it passes the traffic straight through to the back end servers unfettered and does not interfere with the TLS process, leaving this to the Kube API servers.
* Login to `loadbalancer` instance using `vagrant ssh` (or `multipass shell` on Apple Silicon).
  ```bash
  ssh -i ~/.ssh/kubernetes vagrant@192.168.56.60
  ```
* Install haproxy:
  ```bash
  sudo apt-get update && sudo apt-get install -y haproxy
  ```
* Read IP addresses of controlplane nodes and loadbalancer to shell variables
  ```bash
  CONTROL01_IP=$(dig +short controlplane01)
  CONTROL02_IP=$(dig +short controlplane02)
  LOADBALANCER_IP=$(dig +short loadbalancer)
  ```
* Create HAProxy configuration to listen on API server port on this host and distribute requests evently to the two controlplane nodes.
* We configure it to operate as a [layer 4](https://en.wikipedia.org/wiki/Transport_layer) loadbalancer (using `mode tcp`), which means it forwards any traffic directly to the backends without doing anything like [SSL offloading](https://ssl2buy.com/wiki/ssl-offloading).

  ```bash
  cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
  frontend kubernetes
      bind ${LOADBALANCER_IP}:6443
      option tcplog
      mode tcp
      default_backend kubernetes-controlplane-nodes

  backend kubernetes-controlplane-nodes
      mode tcp
      balance roundrobin
      option tcp-check
      server controlplane01 ${CONTROL01_IP}:6443 check fall 3 rise 2
      server controlplane02 ${CONTROL02_IP}:6443 check fall 3 rise 2

  #Add the following configuration at the end of the file:
  listen stats
      bind *:8404
      mode http
      stats enable
      stats uri /
      stats refresh 10s      
  EOF
  ```
  Restart and enable haproxy:
  ```bash
  {
    sudo systemctl daemon-reload
    sudo systemctl enable haproxy.service
    sudo systemctl start haproxy.service
    sudo systemctl status haproxy.service
  }
  ```
  ```bash
  # Allow port 6443 (Kubernetes API Server)
  sudo ufw allow 6443/tcp comment 'HAProxy Kubernetes API'

  # Allow port 8404 (HAProxy stats/metrics)
  sudo ufw allow 8404/tcp comment 'HAProxy Stats'

  # Alternative: Allow from specific IP range (more secure)
  # sudo ufw allow from 192.168.1.0/24 to any port 6443 proto tcp comment 'Kubernetes API from internal network'
  # sudo ufw allow from 192.168.1.0/24 to any port 8404 proto tcp comment 'HAProxy Stats from internal network'

  # Show the updated rules
  sudo ufw status numbered
  ss -tunlp | grep -i -E '6443|8404'
  ```




#### Provision the Kubernetes Control Plane

* Download the latest and official Kubernetes Controller release binaries.
  ```bash
  KUBE_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

  wget -q --show-progress --https-only --timestamping \
    "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kube-apiserver" \
    "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kube-controller-manager" \
    "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kube-scheduler" \
    "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kubectl"
  ```
  Reference: https://kubernetes.io/releases/download/#binaries

* Install the Kubernetes binaries:
  ```bash
  {
    chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
    sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/
  }
  ```

* Configure the Kubernetes API Server
  Place the key pairs into the kubernetes data directory.

  ```bash
  {
    sudo mkdir -p /var/lib/kubernetes/pki

    # Only copy CA keys as we'll need them again for workers.
    sudo cp ca.crt ca.key /var/lib/kubernetes/pki
    for c in kube-apiserver service-account apiserver-kubelet-client etcd-server kube-scheduler kube-controller-manager
    do
      sudo mv "$c.crt" "$c.key" /var/lib/kubernetes/pki/
    done
    sudo chown root:root /var/lib/kubernetes/pki/*
    sudo chmod 600 /var/lib/kubernetes/pki/*
  }
  ```

* The instance internal IP address will be used to advertise the API Server to members of the cluster. 
* The load balancer IP address will be used as the external endpoint to the API servers.
* Retrieve these internal IP addresses:

  ```bash
  LOADBALANCER_IP=$(dig +short loadbalancer)
  ```
* IP addresses of the two controlplane nodes, where the etcd servers are.

  ```bash
  CONTROL01_IP=$(dig +short controlplane01)
  CONTROL02_IP=$(dig +short controlplane02)
  ```
* CIDR ranges used *within* the cluster
  ```bash
  POD_CIDR=10.244.0.0/16
  SERVICE_CIDR=10.96.0.0/16
  ```
* Create the `kube-apiserver.service` systemd unit file:

  ```bash
  cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
  [Unit]
  Description=Kubernetes API Server
  Documentation=https://github.com/kubernetes/kubernetes

  [Service]
  ExecStart=/usr/local/bin/kube-apiserver \\
    --advertise-address=${PRIMARY_IP} \\
    --allow-privileged=true \\
    --apiserver-count=2 \\
    --audit-log-maxage=30 \\
    --audit-log-maxbackup=3 \\
    --audit-log-maxsize=100 \\
    --audit-log-path=/var/log/audit.log \\
    --authorization-mode=Node,RBAC \\
    --bind-address=0.0.0.0 \\
    --client-ca-file=/var/lib/kubernetes/pki/ca.crt \\
    --enable-admission-plugins=NodeRestriction,ServiceAccount \\
    --enable-bootstrap-token-auth=true \\
    --etcd-cafile=/var/lib/kubernetes/pki/ca.crt \\
    --etcd-certfile=/var/lib/kubernetes/pki/etcd-server.crt \\
    --etcd-keyfile=/var/lib/kubernetes/pki/etcd-server.key \\
    --etcd-servers=https://${CONTROL01_IP}:2379,https://${CONTROL02_IP}:2379 \\
    --event-ttl=1h \\
    --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
    --kubelet-certificate-authority=/var/lib/kubernetes/pki/ca.crt \\
    --kubelet-client-certificate=/var/lib/kubernetes/pki/apiserver-kubelet-client.crt \\
    --kubelet-client-key=/var/lib/kubernetes/pki/apiserver-kubelet-client.key\\
    --runtime-config=api/all=true \\
    --service-account-key-file=/var/lib/kubernetes/pki/service-account.crt \\
    --service-account-signing-key-file=/var/lib/kubernetes/pki/service-account.key \\
    --service-account-issuer=https://${LOADBALANCER_IP}:6443 \\
    --service-cluster-ip-range=${SERVICE_CIDR} \\
    --service-node-port-range=30000-32767 \\
    --tls-cert-file=/var/lib/kubernetes/pki/kube-apiserver.crt \\
    --tls-private-key-file=/var/lib/kubernetes/pki/kube-apiserver.key \\
    --v=2
  Restart=on-failure
  RestartSec=5

  [Install]
  WantedBy=multi-user.target
  EOF
  ```

* **Configure the Kubernetes Controller Manager**

  Check `kube-controller-manager` kubeconfig are in place:

  ```bash
  ll /var/lib/kubernetes/kube-controller-manager.kubeconfig          
  #-rw------- 1 root root 512 Mar  6 02:11 /var/lib/kubernetes/kube-controller-manager.kubeconfig
  ```

  Create the `kube-controller-manager.service` systemd unit file:

  ```bash
  cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
  [Unit]
  Description=Kubernetes Controller Manager
  Documentation=https://github.com/kubernetes/kubernetes

  [Service]
  ExecStart=/usr/local/bin/kube-controller-manager \\
    --allocate-node-cidrs=true \\
    --authentication-kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
    --authorization-kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
    --bind-address=127.0.0.1 \\
    --client-ca-file=/var/lib/kubernetes/pki/ca.crt \\
    --cluster-cidr=${POD_CIDR} \\
    --cluster-name=kubernetes \\
    --cluster-signing-cert-file=/var/lib/kubernetes/pki/ca.crt \\
    --cluster-signing-key-file=/var/lib/kubernetes/pki/ca.key \\
    --controllers=*,bootstrapsigner,tokencleaner \\
    --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
    --leader-elect=true \\
    --node-cidr-mask-size=24 \\
    --requestheader-client-ca-file=/var/lib/kubernetes/pki/ca.crt \\
    --root-ca-file=/var/lib/kubernetes/pki/ca.crt \\
    --service-account-private-key-file=/var/lib/kubernetes/pki/service-account.key \\
    --service-cluster-ip-range=${SERVICE_CIDR} \\
    --use-service-account-credentials=true \\
    --v=2
  Restart=on-failure
  RestartSec=5

  [Install]
  WantedBy=multi-user.target
  EOF
  ```

* **Configure the Kubernetes Scheduler**
  
  Move the `kube-scheduler` kubeconfig into place:

  ```bash
  sudo ll /var/lib/kubernetes/kube-scheduler.kubeconfig
  #-rw------- 1 root root 476 Mar  6 02:11 /var/lib/kubernetes/kube-scheduler.kubeconfig
  ```

  Create the `kube-scheduler.service` systemd unit file:

  ```bash
  cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
  [Unit]
  Description=Kubernetes Scheduler
  Documentation=https://github.com/kubernetes/kubernetes

  [Service]
  ExecStart=/usr/local/bin/kube-scheduler \\
    --kubeconfig=/var/lib/kubernetes/kube-scheduler.kubeconfig \\
    --leader-elect=true \\
    --v=2
  Restart=on-failure
  RestartSec=5

  [Install]
  WantedBy=multi-user.target
  EOF
  ```
  Secure kubeconfigs

  ```bash
  sudo chmod 600 /var/lib/kubernetes/*.kubeconfig
  ```

* Start the Controller Services

  ```bash
  {
    sudo systemctl daemon-reload
    sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
    sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
  }
  ```

  > Allow up to 10 seconds for the Kubernetes API Server to fully initialize.


* **Verification**
  
  After running the above commands on both controlplane nodes, run the following on `controlplane01`

  ```bash
  kubectl get componentstatuses --kubeconfig admin.kubeconfig
  ```
  It will give you a deprecation warning here, but that's ok.
  > Output
  ```
  Warning: v1 ComponentStatus is deprecated in v1.19+
  NAME                 STATUS    MESSAGE              ERROR
  controller-manager   Healthy   ok
  scheduler            Healthy   ok
  etcd-0               Healthy   {"health": "true"}
  etcd-1               Healthy   {"health": "true"}
  ```
  > Remember to run the above commands on each controller node: `controlplane01`, and `controlplane02`.

  Make a HTTP request for the Kubernetes version info:
  ```bash
  curl -k https://${LOADBALANCER_IP}:6443/version
  ## The Kubernetes Frontend Load Balancer
  ```

<br>

---

### **Installing Container Runtime on the Kubernetes Worker Nodes**

* Install the Container Runtime Interface (CRI) on both worker nodes. 
* CRI is a standard interface for the management of containers. Since v1.24 the use of dockershim has been fully deprecated and removed from the code base. 
* [Containerd replaces docker](https://kodekloud.com/blog/kubernetes-removed-docker-what-happens-now/) as the container runtime for Kubernetes, and it requires support from [CNI Plugins](https://github.com/containernetworking/plugins) to configure container networks, and [runc](https://github.com/opencontainers/runc) to actually do the job of running containers.

**Reference:** https://github.com/containerd/containerd/blob/main/docs/getting-started.md

* Download and Install Container Networking(on each worker instance)
* Install the container runtime `containerd` from the Ubuntu distribution, and kubectl plus the CNI tools from the Kubernetes distribution. Kubectl is required on `node02` to initialize kubeconfig files for the worker-node auto registration.

* Update the apt package index and install packages needed to use the Kubernetes apt repository:
  ```bash
  {
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl
  }
  ```

* Set up the required kernel modules and make them persistent
  ```bash
    cat << EOF | sudo tee /etc/modules-load.d/k8s.conf
      overlay
      br_netfilter
  EOF

  sudo modprobe overlay
  sudo modprobe br_netfilter
  ```

* Set the required kernel parameters and make them persistent
  ```bash
    cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
      net.bridge.bridge-nf-call-iptables  = 1
      net.bridge.bridge-nf-call-ip6tables = 1
      net.ipv4.ip_forward                 = 1
  EOF

  sudo sysctl --system
  ```

* Determine latest version of Kubernetes and store in a shell variable
  ```bash
  KUBE_LATEST=$(curl -L -s https://dl.k8s.io/release/stable.txt | awk 'BEGIN { FS="." } { printf "%s.%s", $1, $2 }')
  echo $KUBE_LATEST
  ```

* Download the Kubernetes public signing key
  ```bash
  {
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBE_LATEST}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  }
  ```

* Add the Kubernetes apt repository
  ```bash
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBE_LATEST}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
  ```

* Install the container runtime and CNI components
  ```bash
  sudo apt update
  sudo apt-get install -y containerd kubernetes-cni kubectl ipvsadm ipset
  ```

*  Configure the container runtime to use systemd Cgroups. This part is the bit many students miss, and if not done results in a controlplane that comes up, then all the pods start crashlooping. `kubectl` will also fail with an error like `The connection to the server x.x.x.x:6443 was refused - did you specify the right host or port?`
    * Create default configuration and pipe it through `sed` to correctly set Cgroup parameter.
      ```bash
      {
        sudo mkdir -p /etc/containerd
        containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' | sudo tee /etc/containerd/config.toml
      }
      ```
    * Restart containerd
      ```bash
      sudo systemctl restart containerd
      ```

<br>

---


### **Bootstrapping the Kubernetes Worker Nodes**

* We will now install the kubernetes components
  - [kubelet](https://kubernetes.io/docs/admin/kubelet)
  - [kube-proxy](https://kubernetes.io/docs/concepts/cluster-administration/proxies).

* [Why we did not install kubelet and kubeproxy on control plane nodes?](/files/kube-proxy.md)

* The Certificates and Configuration are created on `controlplane01` node and then copied over to workers using `scp`.

* Once this is done, the commands are to be run on first worker instance: `node01`. Login to first worker instance using SSH Terminal.

* Kubernetes uses a [special-purpose authorization mode](https://kubernetes.io/docs/admin/authorization/node/) called Node Authorizer, that specifically authorizes API requests made by [Kubelets](https://kubernetes.io/docs/concepts/overview/components/#kubelet). In order to be authorized by the Node Authorizer, Kubelets must use a credential that identifies them as being in the `system:nodes` group, with a username of `system:node:<nodeName>`. In this section you will create a certificate for each Kubernetes worker node that meets the Node Authorizer requirements.

**Provisioning Kubelet Client Certificates:**

* Generate a certificate and private key for one worker node(on `Jumphost`):
  ```bash
  NODE01_IP=$(dig +short node01)
  ```

  ```bash
  cat > openssl-node01.cnf <<EOF
  [req]
  req_extensions = v3_req
  distinguished_name = req_distinguished_name
  [req_distinguished_name]
  [ v3_req ]
  basicConstraints = CA:FALSE
  keyUsage = nonRepudiation, digitalSignature, keyEncipherment
  subjectAltName = @alt_names
  [alt_names]
  DNS.1 = node01
  IP.1 = ${NODE01_IP}
  EOF

  openssl genrsa -out node01.key 2048

  openssl req -new -key node01.key -subj "/CN=system:node:node01/O=system:nodes" -out node01.csr -config openssl-node01.cnf
  
  openssl x509 -req -in node01.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out node01.crt -extensions v3_req -extfile openssl-node01.cnf -days 1000
  ```

  Results:

  ```
  node01.key
  node01.crt
  ```


**The kubelet Kubernetes Configuration File:**

* When generating kubeconfig files for Kubelets the client certificate matching the Kubelet's node name must be used. This will ensure Kubelets are properly authorized by the Kubernetes [Node Authorizer](https://kubernetes.io/docs/admin/authorization/node/).

* Get the kube-api server load-balancer IP.
  ```bash
  LOADBALANCER_IP=$(dig +short loadbalancer)
  ```

* Generate a kubeconfig file for the first worker node(On `Jumphost`).
  ```bash
  {
    kubectl config set-cluster kubernetes-the-hard-way \
      --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
      --server=https://${LOADBALANCER_IP}:6443 \
      --kubeconfig=node01.kubeconfig

    kubectl config set-credentials system:node:node01 \
      --client-certificate=/var/lib/kubernetes/pki/node01.crt \
      --client-key=/var/lib/kubernetes/pki/node01.key \
      --kubeconfig=node01.kubeconfig

    kubectl config set-context default \
      --cluster=kubernetes-the-hard-way \
      --user=system:node:node01 \
      --kubeconfig=node01.kubeconfig

    kubectl config use-context default --kubeconfig=node01.kubeconfig
  }
  ```

  Results:

  ```
  node01.kubeconfig
  ```

* Copy certificates, private keys and kubeconfig files to the worker node:
  ```bash
  scp -i ~/.ssh/kubernetes ca.crt node01.crt node01.key node01.kubeconfig node01:~/
  ```


**Download and Install Worker Binaries**

* All the following commands from here until the [verification](#verification) step must be run on `node01`

  ```bash
  KUBE_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

  wget -q --show-progress --https-only --timestamping \
    https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kube-proxy \
    https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kubelet 
  ```

  Reference: https://kubernetes.io/releases/download/#binaries

  Create the installation directories:

  ```bash
  sudo mkdir -p \
    /var/lib/kubelet \
    /var/lib/kube-proxy \
    /var/lib/kubernetes/pki 
  ```

* Install the worker binaries:

  ```bash
  {
    chmod +x kube-proxy kubelet
    sudo mv kube-proxy kubelet /usr/local/bin/
  }
  ```

**Configure the Kubelet(On `node01`):**
* Copy keys and config to correct directories and secure

  ```bash
  {
    sudo mv ${HOSTNAME}.key ${HOSTNAME}.crt /var/lib/kubernetes/pki/
    sudo mv ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubelet.kubeconfig
    sudo mv ca.crt /var/lib/kubernetes/pki/
    sudo mv kube-proxy.crt kube-proxy.key /var/lib/kubernetes/pki/
    sudo chown root:root /var/lib/kubernetes/pki/*
    sudo chmod 600 /var/lib/kubernetes/pki/*
    sudo chown root:root /var/lib/kubelet/*
    sudo chmod 600 /var/lib/kubelet/*
  }
  ```

* CIDR ranges used *within* the cluster

  ```bash
  POD_CIDR=10.244.0.0/16
  SERVICE_CIDR=10.96.0.0/16
  ```

* Compute cluster DNS addess, which is conventionally .10 in the service CIDR range

  ```bash
  CLUSTER_DNS=$(echo $SERVICE_CIDR | awk 'BEGIN {FS="."} ; { printf("%s.%s.%s.10", $1, $2, $3) }')
  ```

* Create the `kubelet-config.yaml` configuration file:
  
  Reference: https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/

  ```bash
  cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
  kind: KubeletConfiguration
  apiVersion: kubelet.config.k8s.io/v1beta1
  authentication:
    anonymous:
      enabled: false
    webhook:
      enabled: true
    x509:
      clientCAFile: /var/lib/kubernetes/pki/ca.crt
  authorization:
    mode: Webhook
  containerRuntimeEndpoint: unix:///var/run/containerd/containerd.sock
  clusterDomain: cluster.local
  clusterDNS:
    - ${CLUSTER_DNS}
  cgroupDriver: systemd
  resolvConf: /run/systemd/resolve/resolv.conf
  runtimeRequestTimeout: "15m"
  tlsCertFile: /var/lib/kubernetes/pki/${HOSTNAME}.crt
  tlsPrivateKeyFile: /var/lib/kubernetes/pki/${HOSTNAME}.key
  registerNode: true
  EOF
  ```

* The `resolvConf` configuration is used to avoid loops when using CoreDNS for service discovery on systems running `systemd-resolved`.([look](/files/resolve.md))

* Create the `kubelet.service` systemd unit file:

  ```bash
  cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
  [Unit]
  Description=Kubernetes Kubelet
  Documentation=https://github.com/kubernetes/kubernetes
  After=containerd.service
  Requires=containerd.service

  [Service]
  ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --kubeconfig=/var/lib/kubelet/kubelet.kubeconfig \\        # ← keep this
  --bootstrap-kubeconfig=/var/lib/kubelet/bootstrap-kubeconfig \\  # ← first-time auth
  --node-ip=${PRIMARY_IP} \\
  --image-pull-progress-deadline=2m \\
  --rotate-certificates=true \\
  --rotate-server-certificates=true \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
  Restart=on-failure
  RestartSec=5

  [Install]
  WantedBy=multi-user.target
  EOF
  ```

* Configure the Kubernetes Proxy(On `node01`)

  ```bash
  ll /var/lib/kube-proxy/kube-proxy.kubeconfig
  #-rw------- 1 root root 464 Mar  6 02:11 /var/lib/kube-proxy/kube-proxy.kubeconfig
  ```

* Create the `kube-proxy-config.yaml` configuration file:
  
  Reference: https://kubernetes.io/docs/reference/config-api/kube-proxy-config.v1alpha1/

  ```bash
  cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
  kind: KubeProxyConfiguration
  apiVersion: kubeproxy.config.k8s.io/v1alpha1
  clientConnection:
    kubeconfig: /var/lib/kube-proxy/kube-proxy.kubeconfig
  mode: iptables
  clusterCIDR: ${POD_CIDR}
  EOF
  ```

* Create the `kube-proxy.service` systemd unit file:

  ```bash
  cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
  [Unit]
  Description=Kubernetes Kube Proxy
  Documentation=https://github.com/kubernetes/kubernetes

  [Service]
  ExecStart=/usr/local/bin/kube-proxy \\
    --config=/var/lib/kube-proxy/kube-proxy-config.yaml
  Restart=on-failure
  RestartSec=5

  [Install]
  WantedBy=multi-user.target
  EOF
  ```

* Start the Worker Services(On `node01`):

  ```bash
  {
    sudo systemctl daemon-reload
    sudo systemctl enable kubelet kube-proxy
    sudo systemctl start kubelet kube-proxy
  }
  ```

## Verification(on `controlplane01`)

* List the registered Kubernetes nodes from the controlplane node:

  ```bash
  kubectl get nodes --kubeconfig admin.kubeconfig
  ```
* Output will be similar to

  ```
  NAME       STATUS     ROLES    AGE   VERSION
  node01     NotReady   <none>   93s   v1.28.4
  ```

* The node is not ready as we have not yet installed pod networking. This comes later.

<br>

---

### **TLS Bootstrapping Worker Nodes**

* In the previous step we configured a worker node by:
  * Creating a set of key pairs for the worker node by ourself.
  * Getting them signed by the CA by ourself.
  * Creating a kube-config file using this certificate by ourself.
  * Everytime the certificate expires we must follow the same process of updating the certificate by ourself.

* This is not a practical approach when you could have 1000s of nodes in the cluster, and nodes dynamically being added and removed from the cluster.  With TLS boostrapping:
  * The Nodes can generate certificate key pairs by themselves
  * The Nodes can generate certificate signing request by themselves
  * The Nodes can submit the certificate signing request to the Kubernetes CA (Using the Certificates API)
  * The Nodes can retrieve the signed certificate from the Kubernetes CA
  * The Nodes can generate a kube-config file using this certificate by themselves
  * The Nodes can start and join the cluster by themselves
  * The Nodes can request new certificates via a CSR, but the CSR must be manually approved by a cluster administrator

* In Kubernetes 1.11 a patch was merged to require administrator or Controller approval of node serving CSRs for security reasons.
* Reference: https://kubernetes.io/docs/reference/access-authn-authz/kubelet-tls-bootstrapping/#certificate-rotation

<br>

**What is required for TLS Bootstrapping**
* **Certificates API:** The Certificate API provides a set of APIs on Kubernetes that can help us manage certificates (Create CSR, Get them signed by CA, Retrieve signed certificate etc). The worker nodes (kubelets) have the ability to use this API to get certificates signed by the Kubernetes CA.

* **kube-apiserver** - Ensure bootstrap token based authentication is enabled on the kube-apiserver.
  * Run this command on `controlplane01` :
    ```bash
    grep 'enable-bootstrap-token-auth=true' /etc/systemd/system/kube-apiserver.service
    ```
  * Expected output : 
    `  --enable-bootstrap-token-auth=true \`

* **kube-controller-manager** - The certificate requests are signed by the kube-controller-manager ultimately. The kube-controller-manager requires the CA Certificate and Key to perform these operations.

  ```bash
    --cluster-signing-cert-file=/var/lib/kubernetes/ca.crt \\
    --cluster-signing-key-file=/var/lib/kubernetes/ca.key
  ```
  > Note: We have already configured these in lab 8 in this course


**Step 1 Create the Boostrap Token to be used by Nodes (Kubelets) to invoke Certificate API**

* Run the following steps on `controlplane01`
* For the workers(kubelet) to access the Certificates API, they need to authenticate to the kubernetes api-server first. For this we create a [Bootstrap Token](https://kubernetes.io/docs/reference/access-authn-authz/bootstrap-tokens/) to be used by the kubelet
* Bootstrap Tokens take the form of a 6 character token id followed by 16 character token secret separated by a dot. Eg: abcdef.0123456789abcdef. More formally, they must match the regular expression `[a-z0-9]{6}\.[a-z0-9]{16}`

* Set an expiration date for the bootstrap token of 7 days from now (you can adjust this)
  ```bash
  EXPIRATION=$(date -u --date "+7 days" +"%Y-%m-%dT%H:%M:%SZ")
  ```

  ```bash
  cat > bootstrap-token-07401b.yaml <<EOF
  apiVersion: v1
  kind: Secret
  metadata:
    # Name MUST be of form "bootstrap-token-<token id>"
    name: bootstrap-token-07401b
    namespace: kube-system

  # Type MUST be 'bootstrap.kubernetes.io/token'
  type: bootstrap.kubernetes.io/token
  stringData:
    # Human readable description. Optional.
    description: "The default bootstrap token generated by 'kubeadm init'."

    # Token ID and secret. Required.
    token-id: 07401b
    token-secret: f395accd246ae52d

    # Expiration. Optional.
    expiration: ${EXPIRATION}

    # Allowed usages.
    usage-bootstrap-authentication: "true"
    usage-bootstrap-signing: "true"

    # Extra groups to authenticate the token as. Must start with "system:bootstrappers:"
    auth-extra-groups: system:bootstrappers:worker
  EOF


  kubectl create -f bootstrap-token-07401b.yaml --kubeconfig admin.kubeconfig

  ```

  Things to note:
  - **expiration** - make sure its set to a date in the future. The computed shell variable `EXPIRATION` ensures this.
  - **auth-extra-groups** - this is the group the worker nodes are part of. It must start with "system:bootstrappers:" This group does not exist already. This group is associated with this token.

* Once this is created the token to be used for authentication is `07401b.f395accd246ae52d`
* Reference: https://kubernetes.io/docs/reference/access-authn-authz/bootstrap-tokens/#bootstrap-token-secret-format

**Step 2 Authorize nodes (kubelets) to create CSR**

* Next we associate the group we created before to the `system:node-bootstrapper` ClusterRole. This ClusterRole gives the group enough permissions to bootstrap the kubelet

  ```bash
  kubectl create clusterrolebinding create-csrs-for-bootstrapping \
    --clusterrole=system:node-bootstrapper \
    --group=system:bootstrappers \
    --kubeconfig admin.kubeconfig
  ```
  --------------- OR ---------------

  ```bash
  cat > csrs-for-bootstrapping.yaml <<EOF
  # enable bootstrapping nodes to create CSR
  kind: ClusterRoleBinding
  apiVersion: rbac.authorization.k8s.io/v1
  metadata:
    name: create-csrs-for-bootstrapping
  subjects:
  - kind: Group
    name: system:bootstrappers
    apiGroup: rbac.authorization.k8s.io
  roleRef:
    kind: ClusterRole
    name: system:node-bootstrapper
    apiGroup: rbac.authorization.k8s.io
  EOF


  kubectl create -f csrs-for-bootstrapping.yaml --kubeconfig admin.kubeconfig

  ```
* Reference: https://kubernetes.io/docs/reference/access-authn-authz/kubelet-tls-bootstrapping/#authorize-kubelet-to-create-csr


**Step 3 Authorize nodes (kubelets) to approve CSRs**

  ```bash
  kubectl create clusterrolebinding auto-approve-csrs-for-group \
    --clusterrole=system:certificates.k8s.io:certificatesigningrequests:nodeclient \
    --group=system:bootstrappers \
    --kubeconfig admin.kubeconfig
  ```

  --------------- OR ---------------

  ```bash
  cat > auto-approve-csrs-for-group.yaml <<EOF
  # Approve all CSRs for the group "system:bootstrappers"
  kind: ClusterRoleBinding
  apiVersion: rbac.authorization.k8s.io/v1
  metadata:
    name: auto-approve-csrs-for-group
  subjects:
  - kind: Group
    name: system:bootstrappers
    apiGroup: rbac.authorization.k8s.io
  roleRef:
    kind: ClusterRole
    name: system:certificates.k8s.io:certificatesigningrequests:nodeclient
    apiGroup: rbac.authorization.k8s.io
  EOF

  kubectl create -f auto-approve-csrs-for-group.yaml --kubeconfig admin.kubeconfig
  ```

  Reference: https://kubernetes.io/docs/reference/access-authn-authz/kubelet-tls-bootstrapping/#approval

**Step 4 Authorize nodes (kubelets) to Auto Renew Certificates on expiration**

* We now create the Cluster Role Binding required for the nodes to automatically renew the certificates on expiry. Note that we are NOT using the **system:bootstrappers** group here any more. Since by the renewal period, we believe the node would be bootstrapped and part of the cluster already. All nodes are part of the **system:nodes** group.

  ```bash
  kubectl create clusterrolebinding auto-approve-renewals-for-nodes \
    --clusterrole=system:certificates.k8s.io:certificatesigningrequests:selfnodeclient \
    --group=system:nodes \
    --kubeconfig admin.kubeconfig
  ```

  --------------- OR ---------------

  ```bash
  cat > auto-approve-renewals-for-nodes.yaml <<EOF
  # Approve renewal CSRs for the group "system:nodes"
  kind: ClusterRoleBinding
  apiVersion: rbac.authorization.k8s.io/v1
  metadata:
    name: auto-approve-renewals-for-nodes
  subjects:
  - kind: Group
    name: system:nodes
    apiGroup: rbac.authorization.k8s.io
  roleRef:
    kind: ClusterRole
    name: system:certificates.k8s.io:certificatesigningrequests:selfnodeclient
    apiGroup: rbac.authorization.k8s.io
  EOF


  kubectl create -f auto-approve-renewals-for-nodes.yaml --kubeconfig admin.kubeconfig
  ```
* Reference: https://kubernetes.io/docs/reference/access-authn-authz/kubelet-tls-bootstrapping/#approval

**Step 5 Configure the Binaries on the Worker node**

* Going forward all activities are to be done on the `node02` node until [step 11](#step-11-approve-server-csr).


* Download and Install Worker Binaries
  Note that kubectl is required here to assist with creating the boostrap kubeconfigs for kubelet and kube-proxy

  ```bash
  KUBE_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

  wget -q --show-progress --https-only --timestamping \
    https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kube-proxy \
    https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kubelet
  ```

  Reference: https://kubernetes.io/releases/download/#binaries

  Create the installation directories:

  ```bash
  sudo mkdir -p \
    /var/lib/kubelet/pki \
    /var/lib/kube-proxy \
    /var/lib/kubernetes/pki \
    /var/run/kubernetes
  ```

* Install the worker binaries:

  ```bash
  {
    chmod +x kube-proxy kubelet
    sudo mv kube-proxy kubelet /usr/local/bin/
  }
  ```
* Move the certificates and secure them.

  ```bash
  {
    sudo mv ca.crt kube-proxy.crt kube-proxy.key /var/lib/kubernetes/pki
    sudo chown root:root /var/lib/kubernetes/pki/*
    sudo chmod 600 /var/lib/kubernetes/pki/*
  }
  ```

**Step 6 Configure Kubelet to TLS Bootstrap**

* It is now time to configure the second worker to TLS bootstrap using the token we generated
* For `node01` we started by creating a kubeconfig file with the TLS certificates that we manually generated.
Here, we don't have the certificates yet. So we cannot create a kubeconfig file. Instead we create a bootstrap-kubeconfig file with information about the token we created.
* This is to be done on the `node02` node. Note that now we have set up the load balancer to provide high availibilty across the API servers, we point kubelet to the load balancer.
* Set up some shell variables for nodes and services we will require in the following configurations:

  ```bash
  LOADBALANCER_IP=$(dig +short loadbalancer)
  POD_CIDR=10.244.0.0/16
  SERVICE_CIDR=10.96.0.0/16
  CLUSTER_DNS=$(echo $SERVICE_CIDR | awk 'BEGIN {FS="."} ; { printf("%s.%s.%s.10", $1, $2, $3) }')
  ```

* Set up the bootstrap kubeconfig.

  ```bash
  {
    sudo kubectl config --kubeconfig=/var/lib/kubelet/bootstrap-kubeconfig \
      set-cluster bootstrap --server="https://${LOADBALANCER_IP}:6443" --certificate-authority=/var/lib/kubernetes/pki/ca.crt

    sudo kubectl config --kubeconfig=/var/lib/kubelet/bootstrap-kubeconfig \
      set-credentials kubelet-bootstrap --token=07401b.f395accd246ae52d

    sudo kubectl config --kubeconfig=/var/lib/kubelet/bootstrap-kubeconfig \
      set-context bootstrap --user=kubelet-bootstrap --cluster=bootstrap

    sudo kubectl config --kubeconfig=/var/lib/kubelet/bootstrap-kubeconfig \
      use-context bootstrap
  }
  #--------------- OR ---------------
  {

    cat <<EOF | sudo tee /var/lib/kubelet/bootstrap-kubeconfig
    apiVersion: v1
    clusters:
    - cluster:
        certificate-authority: /var/lib/kubernetes/pki/ca.crt
        server: https://${LOADBALANCER}:6443
      name: bootstrap
    contexts:
    - context:
        cluster: bootstrap
        user: kubelet-bootstrap
      name: bootstrap
    current-context: bootstrap
    kind: Config
    preferences: {}
    users:
    - name: kubelet-bootstrap
      user:
        token: 07401b.f395accd246ae52d
    EOF

  }
  ```
* Reference: https://kubernetes.io/docs/reference/access-authn-authz/kubelet-tls-bootstrapping/#kubelet-configuration


**Step 7 Create Kubelet Config File**

* Create the `kubelet-config.yaml` configuration file:
* Reference: https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/

  ```bash
  cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
  kind: KubeletConfiguration
  apiVersion: kubelet.config.k8s.io/v1beta1
  authentication:
    anonymous:
      enabled: false
    webhook:
      enabled: true
    x509:
      clientCAFile: /var/lib/kubernetes/pki/ca.crt
  authorization:
    mode: Webhook
  containerRuntimeEndpoint: unix:///var/run/containerd/containerd.sock
  cgroupDriver: systemd
  clusterDomain: "cluster.local"
  clusterDNS:
    - ${CLUSTER_DNS}
  registerNode: true
  resolvConf: /run/systemd/resolve/resolv.conf
  rotateCertificates: true
  runtimeRequestTimeout: "15m"
  serverTLSBootstrap: true
  EOF
  ```
  > Note: We are not specifying the certificate details - tlsCertFile and tlsPrivateKeyFile - in this file


**Step 8 Configure Kubelet Service**
  
* Create the `kubelet.service` systemd unit file:

  ```bash
  cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
  [Unit]
  Description=Kubernetes Kubelet
  Documentation=https://github.com/kubernetes/kubernetes
  After=containerd.service
  Requires=containerd.service

  [Service]
  ExecStart=/usr/local/bin/kubelet \\
    --bootstrap-kubeconfig="/var/lib/kubelet/bootstrap-kubeconfig" \\
    --config=/var/lib/kubelet/kubelet-config.yaml \\
    --kubeconfig=/var/lib/kubelet/kubeconfig \\
    --cert-dir=/var/lib/kubelet/pki/ \\
    --node-ip=${PRIMARY_IP} \\
    --v=2
  Restart=on-failure
  RestartSec=5

  [Install]
  WantedBy=multi-user.target
  EOF
  ```

Things to note here:
- **bootstrap-kubeconfig**: Location of the bootstrap-kubeconfig file.
- **cert-dir**: The directory where the generated certificates are stored.
- **kubeconfig**: We specify a location for this *but we have not yet created it*. Kubelet will create one itself upon successful bootstrap.

**Step 9 Configure the Kubernetes Proxy**

* In one of the previous steps we created the kube-proxy.kubeconfig file. Check [here](#the-kube-proxy-kubernetes-configuration-file) if you missed it.


  ```bash
  {
    sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/
    sudo chown root:root /var/lib/kube-proxy/kube-proxy.kubeconfig
    sudo chmod 600 /var/lib/kube-proxy/kube-proxy.kubeconfig
  }
  ```

* Create the `kube-proxy-config.yaml` configuration file:
* Reference: https://kubernetes.io/docs/reference/config-api/kube-proxy-config.v1alpha1/

  ```bash
  cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
  kind: KubeProxyConfiguration
  apiVersion: kubeproxy.config.k8s.io/v1alpha1
  clientConnection:
    kubeconfig: /var/lib/kube-proxy/kube-proxy.kubeconfig
  mode: iptables
  clusterCIDR: ${POD_CIDR}
  EOF
  ```

* Create the `kube-proxy.service` systemd unit file:

  ```bash
  cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
  [Unit]
  Description=Kubernetes Kube Proxy
  Documentation=https://github.com/kubernetes/kubernetes

  [Service]
  ExecStart=/usr/local/bin/kube-proxy \\
    --config=/var/lib/kube-proxy/kube-proxy-config.yaml
  Restart=on-failure
  RestartSec=5

  [Install]
  WantedBy=multi-user.target
  EOF
  ```


**Step 10 Start the Worker Services(On `node02`)**:

  ```bash
  {
    sudo systemctl daemon-reload
    sudo systemctl enable kubelet kube-proxy
    sudo systemctl start kubelet kube-proxy
  }
  ```


**Step 11 Approve Server CSR**
* Now, go back to `controlplane01` and approve the pending kubelet-serving certificate

  ```bash
  kubectl get csr --kubeconfig admin.kubeconfig
  ```

  > Output - Note the name will be different, but it will begin with `csr-`

  ```
  NAME        AGE   SIGNERNAME                                    REQUESTOR                 REQUESTEDDURATION   CONDITION
  csr-7k8nh   85s   kubernetes.io/kubelet-serving                 system:node:node02        <none>              Pending
  csr-n7z8p   98s   kubernetes.io/kube-apiserver-client-kubelet   system:bootstrap:07401b   <none>              Approved,Issued
  ```

  Approve the pending certificate. Note that the certificate name `csr-7k8nh` will be different for you, and each time you run through.

  ```
  kubectl certificate approve --kubeconfig admin.kubeconfig csr-7k8nh
  ```


* Note: In the event your cluster persists for longer than 365 days, you will need to manually approve the replacement CSR.
* Reference: https://kubernetes.io/docs/reference/access-authn-authz/kubelet-tls-bootstrapping/#kubectl-approval

**Verification**
* List the registered Kubernetes nodes from the controlplane node:
  ```bash
  kubectl get nodes --kubeconfig admin.kubeconfig
  ```
  Output will be similar to

  ```
  NAME       STATUS      ROLES    AGE   VERSION
  node01     NotReady    <none>   93s   v1.28.4
  node02     NotReady    <none>   93s   v1.28.4
  ```
  Nodes are still not yet ready. As previously mentioned, this is expected.


<br>

---

### Configuring kubectl for Remote Access

In this lab you will generate a kubeconfig file for the `kubectl` command line utility based on the `admin` user credentials.

> Run the commands in this lab from the same directory used to generate the admin client certificates.

## The Admin Kubernetes Configuration File

Each kubeconfig requires a Kubernetes API Server to connect to. To support high availability the IP address assigned to the external load balancer fronting the Kubernetes API Servers will be used.

[//]: # (host:controlplane01)

On `controlplane01`

Get the kube-api server load-balancer IP.

```bash
LOADBALANCER=$(dig +short loadbalancer)
```

Generate a kubeconfig file suitable for authenticating as the `admin` user:

```bash
{

  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://${LOADBALANCER}:6443

  kubectl config set-credentials admin \
    --client-certificate=admin.crt \
    --client-key=admin.key

  kubectl config set-context kubernetes-the-hard-way \
    --cluster=kubernetes-the-hard-way \
    --user=admin

  kubectl config use-context kubernetes-the-hard-way
}
```

Reference doc for kubectl config [here](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)

## Verification

Check the health of the remote Kubernetes cluster:

```
kubectl get componentstatuses
```

Output will be similar to this. It may or may not list both etcd instances, however this is OK if you verified correct installation of etcd in lab 7.

```
Warning: v1 ComponentStatus is deprecated in v1.19+
NAME                 STATUS    MESSAGE             ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-1               Healthy   {"health":"true"}
etcd-0               Healthy   {"health":"true"}
```

List the nodes in the remote Kubernetes cluster:

```bash
kubectl get nodes
```

> output

```
NAME       STATUS      ROLES    AGE    VERSION
node01     NotReady    <none>   118s   v1.28.4
node02     NotReady    <none>   118s   v1.28.4
```


<br>

---

# Provisioning Pod Network

Container Network Interface (CNI) is a standard interface for managing IP networks between containers across many nodes.

We chose to use CNI - [weave](https://github.com/weaveworks/weave) as our networking option.


### Deploy Weave Network

Some of you may have noticed the announcement that WeaveWorks is no longer trading. At this time, this does not mean that Weave is not a valid CNI. WeaveWorks software has always been and remains to be open source, and as such is still useable. It just means that the company is no longer providing updates. While it continues to be compatible with Kubernetes, we will continue to use it as the other options (e.g. Calico, Cilium) require far more configuration steps.

Deploy weave network. Run only once on the `controlplane01` node. You may see a warning, but this is OK.

[//]: # (host:controlplane01)

On `controlplane01`

```bash
kubectl apply -f "https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s-1.11.yaml"

```

It may take up to 60 seconds for the Weave pods to be ready.

## Verification

[//]: # (command:kubectl rollout status daemonset weave-net -n kube-system --timeout=90s)

List the registered Kubernetes nodes from the controlplane node:

```bash
kubectl get pods -n kube-system
```

Output will be similar to

```
NAME              READY   STATUS    RESTARTS   AGE
weave-net-58j2j   2/2     Running   0          89s
weave-net-rr5dk   2/2     Running   0          89s
```

Once the Weave pods are fully running, the nodes should be ready.

```bash
kubectl get nodes
```

Output will be similar to

```
NAME       STATUS   ROLES    AGE     VERSION
node01     Ready    <none>   4m11s   v1.28.4
node02     Ready    <none>   2m49s   v1.28.4
```

Reference: https://kubernetes.io/docs/tasks/administer-cluster/network-policy-provider/weave-network-policy/#install-the-weave-net-addon

Next: [Kube API Server to Kubelet Connectivity](./14-kube-apiserver-to-kubelet.md)</br>
Prev: [Configuring Kubectl](./12-configuring-kubectl.md)


<br>

---

## RBAC for Kubelet Authorization

In this section you will configure RBAC permissions to allow the Kubernetes API Server to access the Kubelet API on each worker node. Access to the Kubelet API is required for retrieving metrics, logs, and executing commands in pods.

> This tutorial sets the Kubelet `--authorization-mode` flag to `Webhook`. Webhook mode uses the [SubjectAccessReview](https://kubernetes.io/docs/admin/authorization/#checking-api-access) API to determine authorization.

[//]: # (host:controlplane01)

Run the below on the `controlplane01` node.

Create the `system:kube-apiserver-to-kubelet` [ClusterRole](https://kubernetes.io/docs/admin/authorization/rbac/#role-and-clusterrole) with permissions to access the Kubelet API and perform most common tasks associated with managing pods:

```bash
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF
```
Reference: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole

The Kubernetes API Server authenticates to the Kubelet as the `system:kube-apiserver` user using the client certificate as defined by the `--kubelet-client-certificate` flag.

Bind the `system:kube-apiserver-to-kubelet` ClusterRole to the `system:kube-apiserver` user:

```bash
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kube-apiserver
EOF
```
Reference: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding

Next: [DNS Addon](./15-dns-addon.md)</br>
Prev: [Deploy Pod Networking](./13-configure-pod-networking.md)

<br>

---

# Deploying the DNS Cluster Add-on

In this lab you will deploy the [DNS add-on](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) which provides DNS based service discovery, backed by [CoreDNS](https://coredns.io/), to applications running inside the Kubernetes cluster.

## The DNS Cluster Add-on

[//]: # (host:controlplane01)

Deploy the `coredns` cluster add-on:

Note that if you have [changed the service CIDR range](./01-prerequisites.md#service-network) and thus this file, you will need to save your copy onto `controlplane01` (paste to vi, then save) and apply that.

```bash
kubectl apply -f https://raw.githubusercontent.com/mmumshad/kubernetes-the-hard-way/master/deployments/coredns.yaml
```

> output

```
serviceaccount/coredns created
clusterrole.rbac.authorization.k8s.io/system:coredns created
clusterrolebinding.rbac.authorization.k8s.io/system:coredns created
configmap/coredns created
deployment.extensions/coredns created
service/kube-dns created
```

List the pods created by the `kube-dns` deployment:

[//]: # (command:kubectl wait deployment -n kube-system coredns --for condition=Available=True --timeout=90s)

```bash
kubectl get pods -l k8s-app=kube-dns -n kube-system
```

> output

```
NAME                       READY   STATUS    RESTARTS   AGE
coredns-699f8ddd77-94qv9   1/1     Running   0          20s
coredns-699f8ddd77-gtcgb   1/1     Running   0          20s
```

Reference: https://kubernetes.io/docs/tasks/administer-cluster/coredns/#installing-coredns

## Verification

Create a `busybox` pod:

```bash
kubectl run busybox -n default --image=busybox:1.28 --restart Never --command -- sleep 180
```

[//]: # (command:kubectl wait pods -n default -l run=busybox --for condition=Ready --timeout=90s)


List the pod created by the `busybox` pod:

```bash
kubectl get pods -n default -l run=busybox
```

> output

```
NAME                      READY   STATUS    RESTARTS   AGE
busybox-bd8fb7cbd-vflm9   1/1     Running   0          10s
```

Execute a DNS lookup for the `kubernetes` service inside the `busybox` pod:

```bash
kubectl exec -ti -n default busybox -- nslookup kubernetes
```

> output

```
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.96.0.1 kubernetes.default.svc.cluster.local
```

<br>

---

### **Smoke Test**

Performing multiple tasks to check cluster work perfectly or not.

**Data Encryption**

* In this section you will verify the ability to [encrypt secret data at rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#verifying-that-data-is-encrypted).

* Create a generic secret:

  ```bash
  kubectl create secret generic kubernetes-the-hard-way \
    --from-literal="mykey=mydata"
  ```

* Print a hexdump of the `kubernetes-the-hard-way` secret stored in etcd:

  ```bash
  sudo ETCDCTL_API=3 etcdctl get \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/etcd/ca.crt \
    --cert=/etc/etcd/etcd-server.crt \
    --key=/etc/etcd/etcd-server.key\
    /registry/secrets/default/kubernetes-the-hard-way | hexdump -C
  ```

  > output

  ```
  00000000  2f 72 65 67 69 73 74 72  79 2f 73 65 63 72 65 74  |/registry/secret|
  00000010  73 2f 64 65 66 61 75 6c  74 2f 6b 75 62 65 72 6e  |s/default/kubern|
  00000020  65 74 65 73 2d 74 68 65  2d 68 61 72 64 2d 77 61  |etes-the-hard-wa|
  00000030  79 0a 6b 38 73 3a 65 6e  63 3a 61 65 73 63 62 63  |y.k8s:enc:aescbc|
  00000040  3a 76 31 3a 6b 65 79 31  3a 78 cd 3c 33 3a 60 d7  |:v1:key1:x.<3:`.|
  00000050  4c 1e 4c f1 97 ce 75 6f  3d a7 f1 4b 59 e8 f9 2a  |L.L...uo=..KY..*|
  00000060  17 77 20 14 ab 73 85 63  12 12 a4 8d 3c 6e 04 4c  |.w ..s.c....<n.L|
  00000070  e0 84 6f 10 7b 3a 13 10  d0 cd df 81 d0 08 be fa  |..o.{:..........|
  00000080  ea 74 ca 53 b3 b2 90 95  e1 ba bc 3f 88 76 db 8e  |.t.S.......?.v..|
  00000090  e1 1e 17 ea 0d b0 3b e3  e3 df eb 2e 57 76 1d d0  |......;.....Wv..|
  000000a0  25 ca ee 5b f2 27 c7 f2  8e 58 93 e9 28 45 8f 3a  |%..[.'...X..(E.:|
  000000b0  e7 97 bf 74 86 72 fd e7  f1 bb fc f7 2d 10 4d c3  |...t.r......-.M.|
  000000c0  70 1d 08 75 c3 7c 14 55  18 9d 68 73 ec e3 41 3a  |p..u.|.U..hs..A:|
  000000d0  dc 41 8a 4b 9e 33 d9 3d  c0 04 60 10 cf ad a4 88  |.A.K.3.=..`.....|
  000000e0  7b e7 93 3f 7a e8 1b 22  bf 0a                    |{..?z.."..|
  000000ea
  ```

  The etcd key should be prefixed with `k8s:enc:aescbc:v1:key1`, which indicates the `aescbc` provider was used to encrypt the data with the `key1` encryption key.

  Cleanup:
  ```bash
  kubectl delete secret kubernetes-the-hard-way
  ```

**Deployments**
* In this section you will verify the ability to create and manage [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).
* Create a deployment for the [nginx](https://nginx.org/en/) web server:

  ```bash
  kubectl create deployment nginx --image=nginx:alpine
  ```
* List the pod created by the `nginx` deployment:
  ```bash
  kubectl get pods -l app=nginx
  ```
  > output
  ```
  NAME                    READY   STATUS    RESTARTS   AGE
  nginx-dbddb74b8-6lxg2   1/1     Running   0          10s
  ```

**Services**
* In this section you will verify the ability to access applications remotely using [port forwarding](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/).

* Create a service to expose deployment nginx on node ports.
  ```bash
  kubectl expose deploy nginx --type=NodePort --port 80
  ```
  ```bash
  PORT_NUMBER=$(kubectl get svc -l app=nginx -o jsonpath="{.items[0].spec.ports[0].nodePort}")
  ```
* Test to view NGINX page
  ```bash
  curl http://node01:$PORT_NUMBER
  curl http://node02:$PORT_NUMBER
  ```
  > output
  ```
  <!DOCTYPE html>
  <html>
  <head>
  <title>Welcome to nginx!</title>
  # Output Truncated for brevity
  <body>
  ```

**Logs**
* In this section you will verify the ability to [retrieve container logs](https://kubernetes.io/docs/concepts/cluster-administration/logging/).
* Retrieve the full name of the `nginx` pod:
  ```bash
  POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")
  ```
* Print the `nginx` pod logs:
  ```bash
  kubectl logs $POD_NAME
  ```
  > output

  ```
  10.32.0.1 - - [20/Mar/2019:10:08:30 +0000] "GET / HTTP/1.1" 200 612 "-" "curl/7.58.0" "-"
  10.40.0.0 - - [20/Mar/2019:10:08:55 +0000] "GET / HTTP/1.1" 200 612 "-" "curl/7.58.0" "-"
  ```

**Exec**
* In this section you will verify the ability to [execute commands in a container](https://kubernetes.io/docs/tasks/debug-application-cluster/get-shell-running-container/#running-individual-commands-in-a-container).
* Print the nginx version by executing the `nginx -v` command in the `nginx` container:
  ```bash
  kubectl exec -ti $POD_NAME -- nginx -v
  ```
  > output
  ```
  nginx version: nginx/1.23.1
  ```
  Clean up test resources
  ```bash
  kubectl delete pod -n default busybox
  kubectl delete service -n default nginx
  kubectl delete deployment -n default nginx
  ```

---




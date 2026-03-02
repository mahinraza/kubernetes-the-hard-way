# Installing the Client Tools

From this point on, the steps are *exactly* the same for VirtualBox and Apple Silicon as it is now about configuring Kubernetes itself on the Linux hosts which you have now provisioned.

Begin by logging into `controlplane01` using `vagrant ssh` for VirtualBox, or `multipass shell` for Apple Silicon.

## Access all VMs

Here we create an SSH key pair for the user who we are logged in as (this is `vagrant` on VirtualBox, `ubuntu` on Apple Silicon). We will copy the public key of this pair to the other controlplane and both workers to permit us to use password-less SSH (and SCP) go get from `controlplane01` to these other nodes in the context of the user which exists on all nodes.

Generate SSH key pair on `controlplane01` node:

[//]: # (host:controlplane01)

```bash
ssh-keygen -t ed25519 -b 4096 -f ~/.ssh/kubernetes -N ""
```

Leave all settings to default by pressing `ENTER` at any prompt.

Add this key to the local `authorized_keys` (`controlplane01`) as in some commands we `scp` to ourself.

```bash
cat ~/.ssh/kubernetes.pub >> ~/.ssh/authorized_keys
```

Copy the key to the other hosts. You will be asked to enter a password for each of the `ssh-copy-id` commands. The password is:
* VirtualBox - `vagrant`
* Apple Silicon: `ubuntu`

The option `-o StrictHostKeyChecking=no` tells it not to ask if you want to connect to a previously unknown host. Not best practice in the real world, but speeds things up here.

`$(whoami)` selects the appropriate user name to connect to the remote VMs. On VirtualBox this evaluates to `vagrant`; on Apple Silicon it is `ubuntu`.

```bash
chmod +x tools/ssh_config.sh
bash -c tools/ssh_config.sh
```

For each host, the output should be similar to this. If it is not, then you may have entered an incorrect password. Retry the step.

```
Number of key(s) added: 1
```

Verify connection

```bash
chmod +x tools/ssh_verify.sh
bash -c tools/ssh_verify.sh
```


## Install kubectl

The [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl) command line utility is used to interact with the Kubernetes API Server. Download and install `kubectl` from the official release binaries:

Reference: [https://kubernetes.io/docs/tasks/tools/install-kubectl/](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

We will be using `kubectl` early on to generate `kubeconfig` files for the controlplane components.

The environment variable `ARCH` is pre-set during VM deployment according to whether using VirtualBox (`amd64`) or Apple Silicon (`arm64`) to ensure the correct version of this and later software is downloaded for your machine architecture.

### Linux

```bash
chmod +x tools/kubectl_install.sh
bash -c tools/kubectl_install.sh
```

### Verification

Verify `kubectl` is installed:

```
kubectl version --client
```

output will be similar to this, although versions may be newer:

```
Client Version: v1.29.0
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
```

Next: [Certificate Authority](04-certificate-authority.md)<br>
Prev: Compute Resources ([VirtualBox](../VirtualBox/docs/02-compute-resources.md)), ([Apple Silicon](../apple-silicon/docs/02-compute-resources.md))
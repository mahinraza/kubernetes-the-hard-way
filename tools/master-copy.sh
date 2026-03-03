#!/usr/bin/env bash
set -e

for instance in controlplane01 controlplane02; do

  if dig +short ${instance} &> /dev/null; then
    echo "${GREEN}Instance ${instance} is reachable, proceeding with file copy...${NC}"
  else
    echo "${RED}Error: Instance ${instance} is not reachable. Please check your network and DNS settings.${NC}"
    continue
  fi

  if ping -c 1 ${instance} &> /dev/null; then
    echo "${GREEN}Instance ${instance} is responding to ping, proceeding with file copy...${NC}"
  else
    echo "${RED}Error: Instance ${instance} is not responding to ping. Please check your network connectivity.${NC}"
    continue
  fi

  echo "${YELLOW}Copying files to ${instance}...${NC}"
  # Create temp directory and copy files to home directory first
  ssh -o StrictHostKeyChecking=no ${instance} "mkdir -p ~/temp-certs"
  
  # Copy files to temp directory in user's home
  scp -o StrictHostKeyChecking=no \
    ca.crt ca.key \
    kube-apiserver.key kube-apiserver.crt \
    apiserver-kubelet-client.crt apiserver-kubelet-client.key \
    service-account.key service-account.crt \
    kube-controller-manager.key kube-controller-manager.crt \
    kube-scheduler.key kube-scheduler.crt \
    etcd-server.key etcd-server.crt \
    ${instance}:~/temp-certs/
  
  # Move files to proper locations with sudo
  ssh -o StrictHostKeyChecking=no ${instance} "
    sudo mkdir -p /etc/kubernetes/pki/etcd
    sudo mv ~/temp-certs/ca.crt ~/temp-certs/ca.key /etc/kubernetes/pki/
    sudo mv ~/temp-certs/kube-apiserver.crt ~/temp-certs/kube-apiserver.key /etc/kubernetes/pki/
    sudo mv ~/temp-certs/apiserver-kubelet-client.crt ~/temp-certs/apiserver-kubelet-client.key /etc/kubernetes/pki/
    sudo mv ~/temp-certs/service-account.crt ~/temp-certs/service-account.key /etc/kubernetes/pki/
    sudo mv ~/temp-certs/kube-controller-manager.crt ~/temp-certs/kube-controller-manager.key /etc/kubernetes/pki/
    sudo mv ~/temp-certs/kube-scheduler.crt ~/temp-certs/kube-scheduler.key /etc/kubernetes/pki/
    sudo mv ~/temp-certs/etcd-server.crt ~/temp-certs/etcd-server.key /etc/kubernetes/pki/etcd/
    rm -rf ~/temp-certs
  "
  
  echo "${GREEN}Files copied to ${instance} successfully${NC}"
done
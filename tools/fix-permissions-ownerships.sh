#!/bin/bash

fix_controlplane_permissions() {
  local instance=$1
  ssh -o StrictHostKeyChecking=no ${instance} "
    # Ownership
    sudo chown -R root:root /etc/kubernetes/pki
    
    # Directory permissions
    sudo chmod 755 /etc/kubernetes/pki
    sudo chmod 700 /etc/kubernetes/pki/etcd
    
    # File permissions
    sudo find /etc/kubernetes/pki -name '*.crt' -exec chmod 644 {} \;
    sudo find /etc/kubernetes/pki -name '*.key' -exec chmod 600 {} \;
  "
}

fix_node_permissions() {
  local instance=$1
  ssh -o StrictHostKeyChecking=no ${instance} "
    # Ownership
    sudo chown root:root /etc/kubernetes/pki/ca.crt
    sudo chown -R root:root /var/lib/kube-proxy
    
    # Permissions
    sudo chmod 644 /etc/kubernetes/pki/ca.crt
    sudo chmod 755 /var/lib/kube-proxy
    sudo chmod 644 /var/lib/kube-proxy/kube-proxy.crt
    sudo chmod 600 /var/lib/kube-proxy/kube-proxy.key
  "
}

verify_controlplane() {
  local instance=$1
  ssh -o StrictHostKeyChecking=no ${instance} "   
    echo 'PKI directory:' && sudo ls -ld /etc/kubernetes/pki
    echo 'PKI contents:' && sudo ls -l /etc/kubernetes/pki/ | head -n 20
    echo 'etcd directory:' && sudo ls -l /etc/kubernetes/pki/etcd/
  "
}

verify_node() {
  local instance=$1
  ssh -o StrictHostKeyChecking=no ${instance} "
    echo 'PKI directory:' && sudo ls -ld /etc/kubernetes/pki
    echo 'CA certificate:' && sudo ls -l /etc/kubernetes/pki/ca.crt
    echo 'kube-proxy directory:' && sudo ls -ld /var/lib/kube-proxy
    echo 'kube-proxy contents:' && sudo ls -l /var/lib/kube-proxy/
  "
}

# Main execution
echo "${BLUE}Starting Kubernetes certificate permission fix...${NC}"
echo ""

# Fix control planes
for instance in controlplane01 controlplane02; do
  echo "${YELLOW}>>> Changing permissions control plane: ${instance}${NC}"
  if fix_controlplane_permissions $instance; then
    echo "${GREEN}✓ Permissions changed on ${instance}${NC}"
  else
    echo "${RED}✗ Failed to change permissions on ${instance}${NC}"
  fi
  echo ""
done

# Fix nodes
for instance in node01 node02; do
  echo "${YELLOW}>>> Fixing permissions worker node: ${instance}${NC}"
  if fix_node_permissions $instance; then
    echo "${GREEN}✓ Permissions changed on ${instance}${NC}"
  else
    echo "${RED}✗ Failed to change permissions on ${instance}${NC}"
  fi
  echo ""
done

# Verification
echo "${BLUE}=== VERIFICATION ===${NC}"
echo ""

for instance in controlplane01 controlplane02; do
  echo "${YELLOW}Verifying control plane permissions: ${instance}${NC}"
  verify_controlplane $instance
  echo "${YELLOW}-------------------${NC}"
  echo ""
done

for instance in node01 node02; do
  echo "${YELLOW}Verifying worker node permissions: ${instance}${NC}"
  verify_node $instance
  echo "${YELLOW}-------------------${NC}"
  echo ""
done

echo "${GREEN}All done!${NC}"
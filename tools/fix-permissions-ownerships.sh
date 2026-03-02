# Fix everything at once
for instance in controlplane01 controlplane02; do
  ssh -o StrictHostKeyChecking=no ${instance} "
    # Ownership
    sudo chown -R root:root /etc/kubernetes/pki
    
    # Directory permissions
    sudo chmod 755 /etc/kubernetes/pki
    sudo chmod 700 /etc/kubernetes/pki/etcd
    
    # File permissions
    sudo find /etc/kubernetes/pki -name '*.crt' -exec chmod 644 {} \;
    sudo find /etc/kubernetes/pki -name '*.key' -exec chmod 600 {} \;
    
    echo '=== Fixed permissions on ${instance} ==='
  "
done

for instance in node01 node02; do
  ssh -o StrictHostKeyChecking=no ${instance} "
    # Ownership
    sudo chown root:root /etc/kubernetes/pki/ca.crt
    sudo chown -R root:root /var/lib/kube-proxy
    
    # Permissions
    sudo chmod 644 /etc/kubernetes/pki/ca.crt
    sudo chmod 755 /var/lib/kube-proxy
    sudo chmod 644 /var/lib/kube-proxy/kube-proxy.crt
    sudo chmod 600 /var/lib/kube-proxy/kube-proxy.key
    
    echo '=== Fixed permissions on ${instance} ==='
  "
done

for instance in controlplane01 controlplane02; do
  echo "Verify ownership and permissions on ${instance}:"
  ssh -o StrictHostKeyChecking=no ${instance} "   
    ls -ld /etc/kubernetes/pki
    ls -l /etc/kubernetes/pki/ | head -5
    ls -l /etc/kubernetes/pki/etcd/
  "
done

for instance in node01 node02; do
  echo "Verify ownership and permissions on ${instance}:"
  ssh -o StrictHostKeyChecking=no ${instance} "
    ls -ld /etc/kubernetes/pki
    ls -l /etc/kubernetes/pki/ca.crt
    ls -ld /var/lib/kube-proxy
    ls -l /var/lib/kube-proxy/
  "
done

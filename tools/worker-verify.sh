for instance in node01 node02; do

  if dig +short ${instance} &> /dev/null; then
    echo "Instance ${instance} is reachable, proceeding with verification..."
  else
    echo "Error: Instance ${instance} is not reachable. Please check your network and DNS settings."
    continue
  fi

  if ping -c 1 ${instance} &> /dev/null; then
    echo "Instance ${instance} is responding to ping, proceeding with verification..."
  else
    echo "Error: Instance ${instance} is not responding to ping. Please check your network connectivity."
    continue
  fi

  echo "=== Verifying certificates on ${instance} ==="
  ssh -o StrictHostKeyChecking=no ${instance} "
    echo 'Checking PKI directory(/etc/kubernetes/pki/):'
    sudo ls -la /etc/kubernetes/pki/
    
    echo -e '\nChecking kube-proxy directory(/var/lib/kube-proxy/):'
    sudo ls -la /var/lib/kube-proxy/
    
    echo -e '\nVerifying certificate files exist:'
    
    # Check CA certificate
    if [ -f /etc/kubernetes/pki/ca.crt ]; then
      echo '✓ CA certificate present'
    else
      echo '✗ CA certificate missing'
    fi
    
    # Check kube-proxy certificates
    if [ -f /var/lib/kube-proxy/kube-proxy.crt ] && [ -f /var/lib/kube-proxy/kube-proxy.key ]; then
      echo '✓ kube-proxy certificates present'
    else
      echo '✗ kube-proxy certificates missing'
    fi
  "
  echo "======================================"
  echo ""
done
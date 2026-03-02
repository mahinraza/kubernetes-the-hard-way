for instance in controlplane01 controlplane02; do
  echo "=== Verifying certificates on ${instance} ==="
  ssh -o StrictHostKeyChecking=no ${instance} "
    echo 'Checking main PKI directory(/etc/kubernetes/pki/):'
    sudo ls -la /etc/kubernetes/pki/
    
    echo -e '\nChecking etcd directory(/etc/kubernetes/pki/etcd/):'
    sudo ls -la /etc/kubernetes/pki/etcd/
    
    echo -e '\nVerifying certificate files exist:'
    
    # Check CA certificates
    if [ -f /etc/kubernetes/pki/ca.crt ] && [ -f /etc/kubernetes/pki/ca.key ]; then
      echo '✓ CA certificates present'
    else
      echo '✗ CA certificates missing'
    fi
    
    # Check API server certificates
    if [ -f /etc/kubernetes/pki/kube-apiserver.crt ] && [ -f /etc/kubernetes/pki/kube-apiserver.key ]; then
      echo '✓ API server certificates present'
    else
      echo '✗ API server certificates missing'
    fi
    
    # Check apiserver-kubelet-client certificates
    if [ -f /etc/kubernetes/pki/apiserver-kubelet-client.crt ] && [ -f /etc/kubernetes/pki/apiserver-kubelet-client.key ]; then
      echo '✓ apiserver-kubelet-client certificates present'
    else
      echo '✗ apiserver-kubelet-client certificates missing'
    fi
    
    # Check service account certificates
    if [ -f /etc/kubernetes/pki/service-account.crt ] && [ -f /etc/kubernetes/pki/service-account.key ]; then
      echo '✓ service-account certificates present'
    else
      echo '✗ service-account certificates missing'
    fi
    
    # Check controller manager certificates
    if [ -f /etc/kubernetes/pki/kube-controller-manager.crt ] && [ -f /etc/kubernetes/pki/kube-controller-manager.key ]; then
      echo '✓ kube-controller-manager certificates present'
    else
      echo '✗ kube-controller-manager certificates missing'
    fi
    
    # Check scheduler certificates
    if [ -f /etc/kubernetes/pki/kube-scheduler.crt ] && [ -f /etc/kubernetes/pki/kube-scheduler.key ]; then
      echo '✓ kube-scheduler certificates present'
    else
      echo '✗ kube-scheduler certificates missing'
    fi
    
    # Check etcd certificates
    if [ -f /etc/kubernetes/pki/etcd/etcd-server.crt ] && [ -f /etc/kubernetes/pki/etcd/etcd-server.key ]; then
      echo '✓ etcd-server certificates present'
    else
      echo '✗ etcd-server certificates missing'
    fi
    
    echo -e '\nTotal files in /etc/kubernetes/pki/:'
    sudo find /etc/kubernetes/pki/ -type f | wc -l
  "
  echo "======================================"
  echo ""
done
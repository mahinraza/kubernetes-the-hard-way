for instance in node01 node02; do

  if dig +short ${instance} &> /dev/null; then
    echo "Instance ${instance} is reachable, proceeding with file copy..."
  else
    echo "Error: Instance ${instance} is not reachable. Please check your network and DNS settings."
    continue
  fi

  if ping -c 1 ${instance} &> /dev/null; then
    echo "Instance ${instance} is responding to ping, proceeding with file copy..."
  else
    echo "Error: Instance ${instance} is not responding to ping. Please check your network connectivity."
    continue
  fi

  echo "Copying files to ${instance}..."
  # Create temp directory
  ssh -o StrictHostKeyChecking=no ${instance} "mkdir -p ~/temp-certs"
  
  # Copy files to temp directory
  scp -o StrictHostKeyChecking=no \
    ca.crt kube-proxy.crt kube-proxy.key \
    ${instance}:~/temp-certs/
  
  # Move files to proper locations with sudo
  ssh -o StrictHostKeyChecking=no ${instance} "
    sudo mkdir -p /etc/kubernetes/pki
    sudo mkdir -p /var/lib/kube-proxy
    sudo mv ~/temp-certs/ca.crt /etc/kubernetes/pki/
    sudo mv ~/temp-certs/kube-proxy.crt ~/temp-certs/kube-proxy.key /var/lib/kube-proxy/
    rm -rf ~/temp-certs
  "
  
  echo "Files copied to ${instance} successfully"
done
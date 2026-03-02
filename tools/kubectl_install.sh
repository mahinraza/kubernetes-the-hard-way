#!/usr/bin/env bash
set -e

# Get the stable version
VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
echo "Installing kubectl version: $VERSION"
echo "Architecture: $ARCH"
echo "---"

for host in controlplane01 controlplane02 loadbalancer node01 node02; do
    USER=$(whoami)
    echo "Connecting to $host..."
    
    ssh -o ConnectTimeout=5 ${USER}@${host} "
        set -e
        echo 'Installing kubectl on $host...'
        
        # Download kubectl
        curl -LO https://dl.k8s.io/release/${VERSION}/bin/linux/${ARCH}/kubectl 1> /dev/null
        
        # Make executable and move
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
        
        # Verify installation
        echo '✓ kubectl version:'
        kubectl version --client
    "
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully installed kubectl on $host"
    else
        echo "✗ Failed to install kubectl on $host"
    fi
    echo "---"
done

echo "✅ kubectl installation complete on all nodes!"
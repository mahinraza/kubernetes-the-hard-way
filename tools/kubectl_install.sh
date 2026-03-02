#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if ARCH is set
if [ -z "$ARCH" ]; then
    echo -e "${RED}❌ ARCH variable is not set!${NC}"
    echo "Please set ARCH variable first (e.g., export ARCH=amd64 or export ARCH=arm64)"
    exit 1
fi

# Get the stable version
echo -e "${BLUE}📡 Fetching latest kubectl version...${NC}"
VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
echo -e "${GREEN}✅ Installing kubectl version: $VERSION${NC}"
echo -e "${GREEN}📦 Architecture: $ARCH${NC}"
echo "---"

for host in controlplane01 controlplane02 loadbalancer node01 node02; do
    USER=$(whoami)
    echo -e "${YELLOW}🔌 Connecting to $host...${NC}"
    
    # SSH command without color codes inside (they won't work remotely)
    ssh -o ConnectTimeout=5 ${USER}@${host} "
        set -e
        
        echo '📥 Downloading kubectl on $host...'
        if curl -LO https://dl.k8s.io/release/${VERSION}/bin/linux/${ARCH}/kubectl &> /dev/null ; then
            echo '✓ Download complete'
        else
            echo '✗ Download failed'
            exit 1
        fi
        
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
        
        echo '✅ kubectl installed successfully'
        echo '📋 Version:'
        kubectl version --client
    "
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully installed kubectl on $host${NC}"
    else
        echo -e "${RED}✗ Failed to install kubectl on $host${NC}"
    fi
    
    echo "---"
done

echo -e "${GREEN}✅ kubectl installation complete on all nodes!${NC}"
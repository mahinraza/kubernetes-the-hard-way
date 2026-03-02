#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the stable version
echo -e "${BLUE}📡 Fetching latest kubectl version...${NC}"
VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
echo -e "${GREEN}✅ Installing kubectl version: $VERSION${NC}"
echo -e "${GREEN}📦 Architecture: $ARCH${NC}"
echo "---"

for host in controlplane01 controlplane02 loadbalancer node01 node02; do
    USER=$(whoami)
    echo -e "${YELLOW}🔌 Connecting to $host...${NC}"
    
    ssh -o ConnectTimeout=5 ${USER}@${host} "
        set -e
        
        echo -e '${YELLOW}📥 Downloading kubectl on $host...${NC}'
        # Download kubectl with progress
        curl -LO https://dl.k8s.io/release/${VERSION}/bin/linux/${ARCH}/kubectl
        
        if [ $? -eq 0 ]; then
          echo -e "${GREEN}✓ Successfully installed kubectl on $host${NC}"
        else
          echo -e "${RED}✗ Failed to install kubectl on $host${NC}"
        fi

        echo -e '${YELLOW}🔧 Installing kubectl on $host...${NC}'
        # Make executable and move
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
        
        # Verify installation
        echo -e '${GREEN}✅ kubectl installed successfully on $host${NC}'
        echo -e '${BLUE}📋 Version on $host:${NC}'
        kubectl version --client --short
    "
    

    echo "---"
done

echo -e "${GREEN}✅ kubectl installation complete on all nodes!${NC}"
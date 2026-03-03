#!/usr/bin/env bash
set -e

# This script verifies that we can SSH into all the machines in the cluster
USER=$(whoami)

NODES=(controlplane01 controlplane02 loadbalancer node01 node02)

for host in "${NODES[@]}"; do
    echo -e "${GREEN}Connecting to $host...${NC}"
    ssh -o ConnectTimeout=5 ${USER}@${host} -i ~/.ssh/kubernetes "echo '✓ Successfully connected to $host'" &> /dev/null
    if [ $? -eq 0 ]; then
        echo "✓ $host: Connection successful"
    else
        echo "✗ $host: Connection failed"
    fi
    echo "---"
done
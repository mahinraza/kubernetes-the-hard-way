#!/usr/bin/env bash
set -e

# This script verifies that we can SSH into all the machines in the cluster
USER=$(whoami)

NODES=(controlplane01 controlplane02 loadbalancer node01 node02)

for host in "${NODES[@]}"; do
    echo -e "${GREEN}Connecting to $host...${NC}"
    # Use timeout command to prevent hanging (5 second limit)
    if timeout 5 ssh -o ConnectTimeout=3  -o ConnectionAttempts=2 -o StrictHostKeyChecking=no -i ~/.ssh/kubernetes $host "echo OK" 2>/dev/null; then
        echo
    else
        echo -e "${RED}✗ Failed to connect to ${host} - Connection timeout or unreachable${NC}"
    fi
done
#!/usr/bin/env bash
set -e

NODES=(controlplane01 controlplane02 loadbalancer node01 node02)
AVAILABLE_NODES=()

for node in "${NODES[@]}"; do
    echo -ne "  Testing $node... "
    if ping -c 1 -W 2 $node &> /dev/null; then
        echo -e "${GREEN}${node}..OK${NC}"
        AVAILABLE_NODES+=($node)
    else
        echo -e "${RED}Unable to reach $node. Skipping SSH setup for this node.${NC}"
    fi
done

echo -e "${GREEN}Available nodes for SSH setup: ${AVAILABLE_NODES[*]}${NC}"

# This script sets up passwordless SSH access from controlplane01 to all other machines in the cluster
for host in "${AVAILABLE_NODES[@]}"; do
    echo -e "${GREEN}Setting up passwordless SSH from jumphost to $host${NC}"
    sshpass -p "vagrant" ssh-copy-id -o StrictHostKeyChecking=no $(whoami)@$host
done
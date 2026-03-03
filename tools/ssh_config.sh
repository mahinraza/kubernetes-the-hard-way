#!/usr/bin/env bash
set -e

NODES=(controlplane01 controlplane02 loadbalancer node01 node02)
AVAILABLE_NODES=()

for node in "${NODES[@]}"; do
    ping -c 1 $node &> /dev/null
    if [ $? -ne 0 ]; then
        echo "${RED}Unable to reach $node. Skipping SSH setup for this node.${NC}"
    else
        AVAILABLE_NODES+=($node)
    fi
done

echo "${GREEN}Available nodes for SSH setup: ${AVAILABLE_NODES[*]}${NC}"

# This script sets up passwordless SSH access from controlplane01 to all other machines in the cluster
for host in "${AVAILABLE_NODES[@]}"; do
    echo "${GREEN}Setting up passwordless SSH from controlplane01 to $host${NC}"
    sshpass -p "vagrant" ssh-copy-id -o StrictHostKeyChecking=no $(whoami)@$host
done
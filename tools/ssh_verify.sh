#!/usr/bin/env bash
set -e

# This script verifies that we can SSH into all the machines in the cluster
USER=$(whoami)
for host in controlplane01 controlplane02 loadbalancer node01 node02; do
    echo "Connecting to $host..."
    ssh -o ConnectTimeout=5 ${USER}@${host} "echo '✓ Successfully connected to $host'"
    if [ $? -eq 0 ]; then
        echo "✓ $host: Connection successful"
    else
        echo "✗ $host: Connection failed"
    fi
    echo "---"
done
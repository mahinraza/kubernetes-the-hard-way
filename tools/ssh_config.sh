#!/usr/bin/env bash
set -e

# This script sets up passwordless SSH access from controlplane01 to all other machines in the cluster
for host in controlplane02 loadbalancer node01 node02; do
    sshpass -p "vagrant" ssh-copy-id -o StrictHostKeyChecking=no $(whoami)@$host
done
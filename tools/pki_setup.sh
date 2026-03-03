#!/usr/bin/env bash
set -e

# Configuration - CUSTOMIZE THESE VALUES
HOST=$(hostname)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "${YELLOW}This script runs on ${HOST}.${NC}"

export CONTROL01_IP=$(dig +short controlplane01)
export CONTROL02_IP=$(dig +short controlplane02)
export LOADBALANCER_IP=$(dig +short loadbalancer)
export WORKER_NODES=("node01" "node02")
export WORKER_IPS=("$(dig +short node01)" "$(dig +short node02)")
export SERVICE_CLUSTER_IP="10.96.0.1"  # First IP in service CIDR
export CERT_DAYS="3650"  # 10 years
export SERVICE_CIDR=10.96.0.0/24
export API_SERVICE=$(echo $SERVICE_CIDR | awk 'BEGIN {FS="."} ; { printf("%s.%s.%s.1", $1, $2, $3) }')

echo "${YELLOW}Configuration variables set:${NC}"
echo "Control Plane 01 IP: $CONTROL01_IP"
echo "Control Plane 02 IP: $CONTROL02_IP"
echo "Load Balancer IP: $LOADBALANCER_IP"
echo "Service CIDR: $SERVICE_CIDR"
echo "Service Cluster IP: $SERVICE_CLUSTER_IP"
echo "API Service IP: $API_SERVICE"
echo "Worker Nodes: ${WORKER_NODES[*]}"
echo "Worker IPs: ${WORKER_IPS[*]}"
echo "Certificate validity: $CERT_DAYS days"
echo "---------------------------------"

echo -e "Do you want to proceed with PKI setup? This will generate certificates and keys for the cluster. (y/n)"
read -r PROCEED
if [[ "$PROCEED" != "y" && "$PROCEED" != "yes" ]]; then
    echo -e "${RED}PKI setup aborted by user.${NC}"
    exit 1
fi
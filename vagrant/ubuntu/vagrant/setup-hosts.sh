#!/bin/bash
#
# Set up /etc/hosts so we can resolve all the machines in the VirtualBox network
set -e
IFNAME=$1
THISHOST=$2

# Host will have 3 interfaces: lo, DHCP assigned NAT network and static on VM network
# We want the VM network
PRIMARY_IP="$(ip -4 addr show | grep "inet" | egrep -v '(dynamic|127\.0\.0)' | awk '{print $2}' | cut -d/ -f1)"
NETWORK=$(echo $PRIMARY_IP | awk 'BEGIN {FS="."} ; { printf("%s.%s.%s", $1, $2, $3) }')
#sed -e "s/^.*${HOSTNAME}.*/${PRIMARY_IP} ${HOSTNAME} ${HOSTNAME}.local/" -i /etc/hosts

# Export PRIMARY IP as an environment variable
echo "PRIMARY_IP=${PRIMARY_IP}" >> /etc/environment

# Export architecture as environment variable to download correct versions of software
echo "ARCH=amd64"  | sudo tee -a /etc/environment > /dev/null
echo 'export ARCH=amd64' >> ~/.bashrc

sudo tee /etc/profile.d/colors.sh > /dev/null <<EOF
export RED="\033[0;31m"
export GREEN="\033[0;32m"
export YELLOW="\033[1;33m"
export BLUE="\033[0;34m"
export NC="\033[0m"
EOF

# remove ubuntu-jammy entry
sed -e '/^.*ubuntu-jammy.*/d' -i /etc/hosts
sed -e "/^.*$2.*/d" -i /etc/hosts

# Update /etc/hosts about other hosts
cat >> /etc/hosts <<EOF
${NETWORK}.41  controlplane01
${NETWORK}.42  controlplane02
${NETWORK}.51  node01
${NETWORK}.52  node02
${NETWORK}.60  loadbalancer
${NETWORK}.71  jumphost
EOF

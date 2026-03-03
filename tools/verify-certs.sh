#!/usr/bin/env bash
set -e

for instance in controlplane01 controlplane02; do
    echo ""
    echo -e "${BLUE}══════════════════════════════════════${NC}"
    echo -e "${YELLOW}  Node: ${instance}${NC}"
    echo -e "${BLUE}──────────────────────────────────────${NC}"

    for dir in /etc/kubernetes/pki /etc/kubernetes/pki/etcd; do
        echo -e "  ${GREEN}📁${NC} ${dir}"
        ssh -o StrictHostKeyChecking=no ${instance} ls -l ${dir} 2>/dev/null | while read line; do
            echo -e "    ${GREEN}📄${NC} ${line}"
        done
    done

    echo -e "${BLUE}══════════════════════════════════════${NC}"
    echo ""
done

for instance in node01 node02; do
    echo ""
    echo -e "${BLUE}══════════════════════════════════════${NC}"
    echo -e "${YELLOW}  Node: ${instance}${NC}"
    echo -e "${BLUE}──────────────────────────────────────${NC}"
    
    for dir in /etc/kubernetes/pki /var/lib/kube-proxy; do
        echo -e "  ${GREEN}📁${NC} ${dir}"
        ssh -o StrictHostKeyChecking=no ${instance} ls -l ${dir} 2>/dev/null | while read line; do
            echo -e "    ${GREEN}📄${NC} ${line}"
        done
    done
    echo -e "${BLUE}══════════════════════════════════════${NC}"
    echo ""
done

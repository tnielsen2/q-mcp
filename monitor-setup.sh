#!/bin/bash

echo "Monitoring ansible-heezy workflows..."

while true; do
  clear
  echo "=== GitHub Actions Status ==="
  docker exec mcp-tools gh run list --repo tnielsen2/ansible-heezy --limit 5
  
  echo ""
  echo "=== Testing SSH Access ==="
  for host in 192.168.1.15 192.168.1.16 192.168.1.17 192.168.1.18 192.168.1.19; do
    result=$(docker exec mcp-tools ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -i /root/.ssh/mcp_heezy mcp-admin@$host whoami 2>&1)
    if [ $? -eq 0 ]; then
      echo "✓ $host: $result"
    else
      echo "✗ $host: Not ready"
    fi
  done
  
  echo ""
  echo "Press Ctrl+C to stop monitoring"
  sleep 10
done

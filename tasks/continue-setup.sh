#!/bin/bash
# Continue Heezy setup after build completes

echo "Waiting for build to complete..."
while true; do
  status=$(gh run list --repo tnielsen2/ansible-heezy --limit 1 --json status,conclusion -q '.[0]')
  build_status=$(echo $status | jq -r '.status')
  
  if [ "$build_status" = "completed" ]; then
    conclusion=$(echo $status | jq -r '.conclusion')
    echo "Build completed with: $conclusion"
    break
  fi
  
  echo "Still building..."
  sleep 10
done

if [ "$conclusion" != "success" ]; then
  echo "Build failed. Check logs."
  exit 1
fi

echo "Triggering mcp-access playbook..."
gh workflow run "Playbook MCP Access Execution" --repo tnielsen2/ansible-heezy

echo "Waiting for playbook to complete..."
sleep 15

while true; do
  status=$(gh run list --repo tnielsen2/ansible-heezy --workflow "Playbook MCP Access Execution" --limit 1 --json status,conclusion -q '.[0]')
  playbook_status=$(echo $status | jq -r '.status')
  
  if [ "$playbook_status" = "completed" ]; then
    conclusion=$(echo $status | jq -r '.conclusion')
    echo "Playbook completed with: $conclusion"
    break
  fi
  
  echo "Playbook running..."
  sleep 10
done

if [ "$conclusion" != "success" ]; then
  echo "Playbook failed. Check logs."
  exit 1
fi

echo "Testing SSH access..."
for host in 192.168.1.15 192.168.1.16 192.168.1.17 192.168.1.18 192.168.1.19; do
  echo -n "$host: "
  ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i ~/.ssh/mcp_heezy mcp-admin@$host whoami || echo "FAILED"
done

echo "Setup complete!"

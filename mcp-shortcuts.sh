#!/bin/bash
# Quick MCP command wrappers - no timeouts

alias mcp-shell='docker exec mcp-tools sh -c'
alias mcp-gh='docker exec mcp-tools gh'
alias mcp-kubectl='docker exec mcp-tools kubectl'
alias mcp-ssh='docker exec mcp-tools ssh -i /root/.ssh/mcp_heezy -o StrictHostKeyChecking=no'

# Check workflow status
check-workflows() {
  docker exec mcp-tools gh run list --repo tnielsen2/ansible-heezy --limit 5
}

# Test SSH to all k8s hosts
test-ssh() {
  for host in 192.168.1.15 192.168.1.16 192.168.1.17 192.168.1.18 192.168.1.19; do
    echo -n "$host: "
    docker exec mcp-tools ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -i /root/.ssh/mcp_heezy mcp-admin@$host whoami 2>&1 || echo "failed"
  done
}

# Watch workflow (polls every 5s)
watch-workflows() {
  watch -n 5 'docker exec mcp-tools gh run list --repo tnielsen2/ansible-heezy --limit 5'
}

echo "MCP shortcuts loaded. Available commands:"
echo "  check-workflows  - Check GitHub Actions status"
echo "  test-ssh         - Test SSH to all k8s hosts"
echo "  watch-workflows  - Watch workflows (updates every 5s)"
echo "  mcp-shell        - Run shell commands"
echo "  mcp-gh           - Run gh commands"
echo "  mcp-ssh          - SSH to hosts"

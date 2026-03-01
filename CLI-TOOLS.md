# MCP CLI Tools

## Direct MCP Interaction

### Option 1: Interactive CLI
```bash
node mcp-cli.js
```

Then use commands like:
```
shell {"command":"gh run list --repo tnielsen2/ansible-heezy --limit 5"}
ssh {"host":"192.168.1.15","user":"mcp-admin","command":"whoami"}
kubectl {"command":"get nodes"}
```

### Option 2: Monitor Script
```bash
./monitor-setup.sh
```

Polls every 10 seconds to check:
- GitHub Actions workflow status
- SSH connectivity to all k8s hosts

### Option 3: Direct Docker Exec
```bash
# Check workflows
docker exec mcp-tools gh run list --repo tnielsen2/ansible-heezy --limit 5

# Test SSH
docker exec mcp-tools ssh -i /root/.ssh/mcp_heezy mcp-admin@192.168.1.15 whoami

# Run kubectl
docker exec mcp-tools ssh -i /root/.ssh/mcp_heezy mcp-admin@192.168.1.15 "microk8s kubectl get nodes"
```

## Why Timeouts Occur

The IDE integration has request timeouts. Long-running operations (sleep, watch, SSH to unreachable hosts) exceed these limits. Use the CLI tools above for uninterrupted execution.

# MicroK8s Cluster Diagnosis - 2026-02-12

## Problem Summary
All MicroK8s workloads are down. Cluster nodes unreachable except nebula-3 (192.168.1.17).

## Findings

### Node Connectivity
- **nebula-1 (192.168.1.15)**: UNREACHABLE - Cannot SSH
- **nebula-2 (192.168.1.16)**: UNREACHABLE - SSH timeout
- **nebula-3 (192.168.1.17)**: REACHABLE - SSH working
- **nebula-4 (192.168.1.18)**: UNREACHABLE - SSH timeout  
- **nebula-5 (192.168.1.19)**: UNREACHABLE - SSH timeout

### nebula-3 Status
- **MicroK8s**: NOT RUNNING - "microk8s is not running"
- **kubelite service**: Active but restarting frequently (last restart: 2026-02-09 23:29:05)
- **kubectl**: Connection refused to API server (127.0.0.1:16443)
- **Tailscale**: LOGGED OUT - Status shows "Needs login"
- **Network**: enp0s31f6 has correct IP 192.168.1.17/24

### Root Cause
**Tailscale is logged out on all nodes**, preventing:
1. Cross-site connectivity (your MTR shows traffic routing to London instead of local network)
2. MicroK8s cluster communication between nodes
3. Proper routing of 192.168.1.x traffic

The MTR showing "196.168.1.17" routing to London confirms Tailscale subnet routing is broken.

## Required Actions

### Immediate Fix
1. **Re-authenticate Tailscale on all nodes**:
   ```bash
   sudo tailscale up --accept-routes
   ```

2. **Verify Tailscale subnet routes** are advertised from the exit node

3. **Restart MicroK8s** on all nodes after Tailscale is authenticated:
   ```bash
   sudo microk8s stop
   sudo microk8s start
   ```

### Check from nebula-3
```bash
# Login to Tailscale
sudo tailscale up --accept-routes

# Verify status
sudo tailscale status

# Check if other nodes are visible
sudo tailscale ping nebula-1
```

## Next Steps
1. Physical access to nebula-1 (.15) to restore Tailscale
2. SSH to other nodes via nebula-3 if they're on same LAN
3. Verify MicroK8s cluster reforms after Tailscale is restored


## Update: LAN Connectivity Test from nebula-3

All nodes ARE reachable on the local LAN from nebula-3:
- 192.168.1.15 (nebula-1): SSH port responding
- 192.168.1.16 (nebula-2): SSH port responding  
- 192.168.1.18 (nebula-4): SSH port responding
- 192.168.1.19 (nebula-5): SSH port responding

**Issue**: mcp-admin SSH key not configured on nebula-3 for lateral access.

**Solution**: Use password authentication from nebula-3 to fix Tailscale on all nodes.

### Commands to run from nebula-3:
```bash
# For each node (15, 16, 18, 19):
ssh mcp-admin@192.168.1.XX
sudo tailscale up --accept-routes
sudo microk8s start
```

# VPN Container Networking and Firewall Configuration

## Overview

Services running behind VPN containers (like gluetun) require special networking configuration to allow cluster-internal traffic while maintaining VPN security.

## Problem: Services Behind VPN Are Unreachable

### Symptoms
- Other pods in the cluster cannot connect to services behind VPN
- Connection timeouts when accessing VPN-protected services
- Error: `Connection to <service> timed out` or `Operation not permitted`

### Root Cause
Gluetun's firewall blocks all incoming traffic by default, including traffic from other pods in the cluster.

## Solution: Configure Gluetun Firewall

### Required Environment Variables

```yaml
env:
- name: FIREWALL_OUTBOUND_SUBNETS
  value: "10.0.0.0/8,192.168.0.0/16"
- name: FIREWALL_INPUT_PORTS
  value: "<comma-separated-ports>"
```

### Explanation

**FIREWALL_OUTBOUND_SUBNETS:**
- Allows outbound traffic to local networks
- `10.0.0.0/8` - Kubernetes pod network
- `192.168.0.0/16` - Local network (for NFS, etc.)

**FIREWALL_INPUT_PORTS:**
- Opens specific ports for incoming connections
- Must include ALL ports that need to be accessible from the cluster
- Example: `"5030,50300"` for slskd (web UI and Soulseek protocol)

## Example: slskd-vpn Configuration

### Deployment Structure
```yaml
containers:
- name: gluetun
  image: qmcgaw/gluetun:latest
  env:
  - name: FIREWALL_OUTBOUND_SUBNETS
    value: "10.0.0.0/8,192.168.0.0/16"
  - name: FIREWALL_INPUT_PORTS
    value: "5030,50300"
  ports:
  - containerPort: 5030
    name: slskd-http
  - containerPort: 50300
    name: slskd-slsk

- name: slskd
  image: slskd/slskd:latest
  # No ports defined - uses gluetun's network
```

### Service Configuration
```yaml
apiVersion: v1
kind: Service
metadata:
  name: slskd
  namespace: heezy
spec:
  selector:
    app: slskd-vpn  # Must match pod label, not container name
  ports:
  - port: 5030
    targetPort: 5030
    name: http
  - port: 50300
    targetPort: 50300
    name: slsk
```

## Case Study: Soularr → Slskd Connectivity

### Initial Problem
Soularr could not connect to slskd API:
```
HTTPConnectionPool(host='slskd', port=5030): Max retries exceeded
Connection to slskd timed out
```

### Debugging Steps

1. **Verify service exists:**
   ```bash
   kubectl get svc slskd -n heezy
   ```

2. **Check service selector matches pod:**
   ```bash
   kubectl get svc slskd -n heezy -o jsonpath='{.spec.selector}'
   # Should return: {"app":"slskd-vpn"}
   ```

3. **Verify endpoints are populated:**
   ```bash
   kubectl get endpoints slskd -n heezy
   # Should show pod IP and ports
   ```

4. **Test connectivity from another pod:**
   ```bash
   kubectl exec -n heezy deployment/soularr -- \
     python3 -c "import socket; s=socket.socket(); s.settimeout(2); s.connect(('slskd', 5030)); print('Connected')"
   ```

### Solution Applied

1. **Added FIREWALL_INPUT_PORTS to gluetun:**
   ```yaml
   - name: FIREWALL_INPUT_PORTS
     value: "5030,50300"
   ```

2. **Restarted the deployment:**
   ```bash
   kubectl rollout restart deployment/slskd-vpn -n heezy
   ```

3. **Verified connectivity:**
   ```bash
   # Test succeeded after firewall configuration
   kubectl exec -n heezy deployment/soularr -- \
     python3 -c "import socket; s=socket.socket(); s.settimeout(2); s.connect(('slskd', 5030)); print('Connected')"
   # Output: Connected
   ```

## Pod Affinity for Shared Storage

When services need to share RWO (ReadWriteOnce) PVCs, they must run on the same node.

### Problem
```
Multi-Attach error for volume "pvc-xxx"
Volume is already exclusively attached to one node and can't be attached to another
```

### Solution: Pod Affinity
```yaml
affinity:
  podAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
        - key: app
          operator: In
          values:
          - slskd-vpn  # Pod to colocate with
      topologyKey: kubernetes.io/hostname
```

This ensures the pod is scheduled on the same node as the target pod.

## Common Mistakes

### 1. Wrong Service Selector
❌ **Wrong:**
```yaml
selector:
  app: slskd  # Container name
```

✅ **Correct:**
```yaml
selector:
  app: slskd-vpn  # Pod label from deployment
```

### 2. Missing Firewall Ports
❌ **Wrong:**
```yaml
- name: FIREWALL_INPUT_PORTS
  value: "5030"  # Only web UI, missing Soulseek protocol port
```

✅ **Correct:**
```yaml
- name: FIREWALL_INPUT_PORTS
  value: "5030,50300"  # Both web UI and protocol ports
```

### 3. Duplicate Environment Variables
❌ **Wrong:**
```yaml
- name: FIREWALL_INPUT_PORTS
  value: "5030,50300"
- name: FIREWALL_VPN_INPUT_PORTS
  value: "5030,50300"
- name: FIREWALL_INPUT_PORTS  # Duplicate!
  value: "5030,50300"
```

✅ **Correct:**
```yaml
- name: FIREWALL_INPUT_PORTS
  value: "5030,50300"
```

## Testing Connectivity

### From Another Pod
```bash
# Using wget
kubectl exec -n heezy <pod-name> -- wget -O- http://<service>:<port>/health

# Using Python socket
kubectl exec -n heezy <pod-name> -- \
  python3 -c "import socket; s=socket.socket(); s.settimeout(2); s.connect(('<service>', <port>)); print('Connected')"
```

### Check Service Endpoints
```bash
kubectl get endpoints <service-name> -n heezy
```

Should show pod IP and ports. If empty, service selector is wrong.

## Gluetun Environment Variables Reference

| Variable | Purpose | Example |
|----------|---------|---------|
| `FIREWALL_OUTBOUND_SUBNETS` | Allow outbound to local networks | `"10.0.0.0/8,192.168.0.0/16"` |
| `FIREWALL_INPUT_PORTS` | Open ports for incoming traffic | `"5030,50300"` |
| `VPN_SERVICE_PROVIDER` | VPN provider | `"nordvpn"` |
| `VPN_TYPE` | VPN protocol | `"openvpn"` |
| `SERVER_COUNTRIES` | VPN server location | `"Netherlands"` |

## Verifying VPN Exit IP

Ensure traffic is actually exiting through the VPN and not leaking through local connection.

### Check VPN Status in Gluetun
```bash
# Check gluetun logs for VPN connection
kubectl logs -n heezy deployment/slskd-vpn -c gluetun | grep -i "ip"
```

### Verify Public IP from Inside Container
```bash
# Check public IP from the VPN-protected container
kubectl exec -n heezy deployment/slskd-vpn -c slskd -- \
  wget -qO- https://api.ipify.org

# Or using curl
kubectl exec -n heezy deployment/slskd-vpn -c slskd -- \
  curl -s https://api.ipify.org
```

### Compare with Host IP
```bash
# Check your actual public IP (from host)
curl -s https://api.ipify.org

# These IPs should be DIFFERENT
# VPN container should show VPN provider's IP
# Host should show your ISP's IP
```

### Check VPN Connection Details
```bash
# View gluetun control server info
kubectl exec -n heezy deployment/slskd-vpn -c gluetun -- \
  wget -qO- http://localhost:8000/v1/openvpn/status

# Expected output should show:
# - "status": "running"
# - VPN server location
# - Public IP (should match VPN provider's IP)
```

### Verify DNS Leak Protection
```bash
# Check DNS servers being used
kubectl exec -n heezy deployment/slskd-vpn -c slskd -- cat /etc/resolv.conf

# Should show VPN provider's DNS or gluetun's DNS, not your local DNS
```

### Test with IP Geolocation
```bash
# Check IP geolocation
kubectl exec -n heezy deployment/slskd-vpn -c slskd -- \
  wget -qO- https://ipapi.co/json/

# Should show VPN server's country (e.g., Netherlands for NordVPN)
# Not your actual location
```

### Common VPN Leak Issues

**Problem: Traffic not going through VPN**
- Check gluetun logs: `kubectl logs -n heezy deployment/slskd-vpn -c gluetun`
- Look for connection errors or authentication failures
- Verify VPN credentials in secrets

**Problem: DNS leaking**
- Ensure gluetun is managing DNS
- Check `/etc/resolv.conf` inside container
- Should not show `10.152.183.10` (k8s DNS) for external queries

**Problem: Kill switch not working**
- Gluetun should block all traffic if VPN disconnects
- Test by checking logs after VPN disconnect
- Should see firewall blocking traffic

## Summary

When deploying services behind VPN containers:

1. ✅ Configure `FIREWALL_INPUT_PORTS` with ALL required ports
2. ✅ Configure `FIREWALL_OUTBOUND_SUBNETS` for cluster/local network access
3. ✅ Ensure service selector matches pod labels (not container names)
4. ✅ Use pod affinity when sharing RWO PVCs
5. ✅ Test connectivity after deployment
6. ✅ Verify VPN exit IP is different from host IP
7. ✅ Check for DNS leaks
8. ✅ Check gluetun logs for firewall blocks if issues persist

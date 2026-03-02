# Prometheus Kubernetes Metrics Collection

## Overview

Prometheus running outside a Kubernetes cluster needs special configuration to scrape kubelet cadvisor metrics for container network, CPU, and memory data.

## Problem: Kubelet Metrics Unauthorized

### Symptoms
- Grafana Kubernetes dashboards show "No Data"
- Missing metrics: `container_network_receive_bytes_total`, `container_cpu_usage_seconds_total`, `container_memory_usage_bytes`
- Prometheus targets show cadvisor endpoints as DOWN
- Error: "Unauthorized" when accessing `https://NODE:10250/metrics/cadvisor`

### Root Cause
Direct kubelet access (port 10250) requires authentication that external Prometheus cannot satisfy, even with proper RBAC permissions.

## Solution: Use API Server Proxy

Access kubelet metrics through the Kubernetes API server proxy instead of directly.

### Required Components

1. **Service Account with Token**
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: kube-system
---
apiVersion: v1
kind: Secret
metadata:
  name: prometheus-token
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: prometheus
type: kubernetes.io/service-account-token
```

2. **ClusterRole with Permissions**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroups: [""]
  resources:
  - nodes
  - nodes/metrics
  - nodes/stats
  - nodes/proxy
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
- nonResourceURLs:
  - /metrics
  - /metrics/cadvisor
  - /metrics/resource
  verbs: ["get"]
```

3. **ClusterRoleBinding**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: kube-system
```

### Prometheus Configuration

**Use API server proxy path instead of direct kubelet access:**

```yaml
scrape_configs:
  - job_name: 'cadvisor'
    scrape_interval: 15s
    scheme: https
    tls_config:
      insecure_skip_verify: true
    bearer_token_file: /etc/prometheus/token
    kubernetes_sd_configs:
      - role: node
        kubeconfig_file: /etc/prometheus/kubeconfig
    relabel_configs:
      - source_labels: [__meta_kubernetes_node_name]
        target_label: node
      - target_label: __address__
        replacement: 192.168.1.15:16443  # API server address
      - source_labels: [__meta_kubernetes_node_name]
        regex: (.+)
        target_label: __metrics_path__
        replacement: /api/v1/nodes/${1}/proxy/metrics/cadvisor
```

**Key differences from direct kubelet access:**
- `__address__` points to API server (port 16443), not kubelet (port 10250)
- `__metrics_path__` uses `/api/v1/nodes/${node}/proxy/metrics/cadvisor`
- No `labelmap` action (causes too many labels for Mimir)

### File Setup on Prometheus Host

1. **Extract and deploy token:**
```bash
kubectl get secret prometheus-token -n kube-system -o jsonpath='{.data.token}' | base64 -d > /etc/prometheus/token
chown 1000:1000 /etc/prometheus/token
chmod 600 /etc/prometheus/token
```

2. **Extract and deploy kubeconfig:**
```bash
kubectl config view --flatten --minify > /etc/prometheus/kubeconfig
chown 1000:1000 /etc/prometheus/kubeconfig
chmod 600 /etc/prometheus/kubeconfig
```

3. **Mount files in Prometheus container:**
```yaml
volumes:
  - /etc/prometheus/token:/etc/prometheus/token:ro
  - /etc/prometheus/kubeconfig:/etc/prometheus/kubeconfig:ro
```

## Common Issues

### Issue: Token file empty in container
**Symptom:** `cat /etc/prometheus/token` returns nothing inside container
**Cause:** File not mounted in docker-compose/container config
**Fix:** Add volume mount to container configuration

### Issue: Metrics have too many labels
**Symptom:** Mimir rejects metrics with "exceeds the limit (actual: 60, limit: 30)"
**Cause:** Using `labelmap` action copies all node labels to metrics
**Fix:** Remove `labelmap` action, only keep essential labels like `node`

### Issue: Token works from one host but not another
**Symptom:** `curl` with token succeeds from k8s node but fails from Prometheus host
**Cause:** Token file corrupted or has different content
**Fix:** Verify MD5 hash matches:
```bash
kubectl get secret prometheus-token -n kube-system -o jsonpath='{.data.token}' | base64 -d | md5sum
md5sum /etc/prometheus/token
```

### Issue: All cadvisor targets show DOWN
**Symptom:** `up{job="cadvisor"}` returns 0 for all targets
**Causes:**
1. Token file not mounted in container
2. Token file has wrong permissions (not readable by UID 1000)
3. API server address incorrect in relabel config
4. Kubeconfig has wrong API server address

**Debug:**
```bash
# Test from Prometheus host
TOKEN=$(cat /etc/prometheus/token)
curl -k -H "Authorization: Bearer ${TOKEN}" \
  https://192.168.1.15:16443/api/v1/nodes/nebula-1/proxy/metrics/cadvisor | head -5

# Should return cadvisor metrics, not "Unauthorized"
```

## Verification

### Check Targets in Prometheus
```bash
curl -s http://localhost:9090/api/v1/targets | grep cadvisor
```

### Check Metrics Available
```bash
curl -s 'http://localhost:9090/api/v1/query?query=container_network_receive_bytes_total' | grep container_network
```

### Check Target Status
```bash
curl -s http://localhost:9090/api/v1/query?query=up | grep cadvisor
# Should show "value":[timestamp,"1"] for UP targets
```

## Why Not Direct Kubelet Access?

**Attempted but failed:**
- Direct access to `https://NODE:10250/metrics/cadvisor` with bearer token
- Even with correct RBAC ClusterRole permissions
- Even with `nonResourceURLs` for `/metrics/cadvisor`

**Root cause:**
- MicroK8s API server uses `--authorization-mode=AlwaysAllow`
- Kubelet enforces its own authentication/authorization
- External tokens cannot authenticate directly to kubelet
- API server proxy validates token and forwards request

**Solution:**
- Route through API server proxy: `/api/v1/nodes/{node}/proxy/metrics/cadvisor`
- API server validates token against RBAC
- API server proxies request to kubelet with its own credentials

## Summary

For external Prometheus to scrape Kubernetes metrics:

1. ✅ Create ServiceAccount + Secret in kube-system namespace
2. ✅ Create ClusterRole with nodes/proxy and nonResourceURLs permissions
3. ✅ Extract token and kubeconfig to Prometheus host
4. ✅ Set correct ownership (1000:1000) and permissions (600)
5. ✅ Mount token and kubeconfig files in Prometheus container
6. ✅ Configure scrape job to use API server proxy path
7. ✅ Use kubernetes_sd with node role for dynamic discovery
8. ✅ Avoid labelmap action to prevent label limit issues
9. ✅ Verify token works with curl before expecting Prometheus to work

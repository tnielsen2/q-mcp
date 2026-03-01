# Adding New Services to heezy-k8s

## Complete Checklist

### 1. Create App Directory
```bash
mkdir -p /workspace/heezy-k8s/apps/<service-name>
```

### 2. Create deployment.yaml
Required components:
- Deployment with proper labels (`app: <service-name>`)
- Node affinity (nebula-1 through nebula-5)
- Container with image, ports, env vars
- Volume mounts for config/data
- Resource requests/limits
- Service (ClusterIP) for internal access

### 3. Create pvc.yaml
- PVC for config storage (typically 5Gi Longhorn)
- Additional PVCs if needed for data
- Consider if NFS volumes are needed (for media access)

### 4. Create kustomization.yaml
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - pvc.yaml
  - deployment.yaml
```

### 5. Deploy to Cluster
```bash
kubectl apply -k /workspace/heezy-k8s/apps/<service-name>/
kubectl wait --for=condition=ready pod -l app=<service-name> -n heezy --timeout=60s
kubectl get pods -n heezy -l app=<service-name> -o wide
```

### 6. Add NodePort (if external access needed)
Edit `/workspace/heezy-k8s/apps/media-nodeports.yaml`:
```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: <service-name>-nodeport
  namespace: heezy
spec:
  type: NodePort
  selector:
    app: <service-name>
  ports:
  - port: <internal-port>
    targetPort: <internal-port>
    nodePort: <30000-32767>
```

Apply:
```bash
kubectl apply -f /workspace/heezy-k8s/apps/media-nodeports.yaml
```

### 7. Commit to Git
```bash
cd /workspace/heezy-k8s
git add apps/<service-name>/
git add apps/media-nodeports.yaml  # if NodePort added
git commit -m "Add <service-name> service"
git push origin main
```

### 8. Verify GitHub Actions
- Push triggers auto-deploy workflow
- Check workflow completes successfully
- Verify pod is running after deployment

## Common Patterns

### Standard LinuxServer.io Container
```yaml
env:
- name: PUID
  value: "1000"
- name: PGID
  value: "1000"
- name: TZ
  value: "UTC"
```

### NFS Media Access
Add to volumes:
```yaml
- name: media
  persistentVolumeClaim:
    claimName: nfs-media-music  # or nfs-media-movies, nfs-media-tv
```

### VPN Sidecar (like slskd-vpn)
- Use gluetun container as sidecar
- Set `FIREWALL_INPUT_PORTS` for exposed ports
- Service selector must match pod label

### Pod Affinity (for shared PVC access)
When sharing RWO PVC with another pod:
```yaml
affinity:
  podAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
        - key: app
          operator: In
          values:
          - <other-pod-name>
      topologyKey: kubernetes.io/hostname
```

## Troubleshooting

### Pod Stuck in ContainerCreating
- Check PVC is bound: `kubectl get pvc -n heezy`
- Check events: `kubectl get events -n heezy --sort-by='.lastTimestamp'`
- Multi-attach error: Add pod affinity to colocate pods

### Service Not Accessible
- Verify service selector matches pod labels
- Check endpoints: `kubectl get endpoints <service-name> -n heezy`
- Test from another pod: `kubectl exec -n heezy <pod> -- wget -O- http://<service>:<port>`

### Firewall Issues (VPN containers)
- Ensure `FIREWALL_INPUT_PORTS` includes all exposed ports
- Check gluetun logs for blocked connections
- Test connectivity from same node first

## Port Assignments

Current NodePort assignments:
- 30001: aurral
- 30030: slskd (http)
- 30076: nzbhydra2
- 30080: sabnzbd
- 30081: qbittorrent
- 30181: tautulli
- 30299: lazylibrarian
- 30300: slskd (slsk protocol)
- 30533: navidrome
- 30686: lidarr
- 30696: prowlarr
- 30878: radarr
- 30989: sonarr
- 32400: plex

Choose unused port in 30000-32767 range for new services.

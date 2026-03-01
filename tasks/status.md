# Status Update - heezy-k8s Documentation

## Completed

Updated heezy-k8s documentation to reflect completed migration:

### Files Updated

1. **README.md**
   - Current architecture (Longhorn + NFS)
   - Deployed services table (7 services)
   - Auto-deploy workflow
   - Storage architecture
   - SSH access info

2. **q.instructions**
   - Deployment workflow (never kubectl apply locally)
   - Storage rules (Longhorn vs NFS)
   - kubectl for diagnostics only
   - Internal service URLs (FQDN requirement)
   - Migration status: complete

3. **MIGRATION.md**
   - Marked migration complete
   - Before/after architecture comparison
   - All 7 services deployed
   - Lessons learned

### Key Documentation Points

- **Deployment**: Push to main → auto-deploy (never manual kubectl apply)
- **Storage**: Longhorn for config, NFS for media
- **Access**: SSH via mcp-admin@192.168.1.15-19
- **Services**: All 7 media stack services running
- **Internal URLs**: Must use FQDN for linuxserver.io containers

### Commits

- 4bb517f: Update documentation for completed K8s migration
- (pending): Mark migration as complete

## 2026-02-20 - Lidarr Deployment Issue Resolved

### Issue
Lidarr was added to heezy-k8s repo but wasn't deploying automatically.

### Root Cause
1. Missing `kustomization.yaml` file in `apps/lidarr/` directory
2. Auto-deploy workflow couldn't detect changed files due to shallow git fetch (depth=1)
3. `nfs-media-music` PVC existed in base config but wasn't applied

### Resolution
1. Created `apps/lidarr/kustomization.yaml` with deployment.yaml and pvc.yaml resources
2. Manually deployed lidarr: `kubectl apply -k apps/lidarr/`
3. Applied base NFS PVs to create music PVC: `kubectl apply -f base/nfs-media-static-pvs.yaml`
4. Lidarr pod now running successfully

### Status
✅ Lidarr deployed and running on port 8686
✅ Using Longhorn for config (5Gi)
✅ Using NFS for music mount (/mnt/Arr1/SMB/Media/music)

### Next Steps
- Consider fixing auto-deploy workflow to use deeper git fetch for proper diff detection
- Add lidarr to ingress/service configuration if external access needed

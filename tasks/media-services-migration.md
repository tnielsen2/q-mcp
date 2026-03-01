# Media Services Migration to K8s

## Current State (192.168.1.14)

### Running Services
- **Sonarr**: linuxserver/sonarr:latest (port 8989)
- **Radarr**: linuxserver/radarr:latest (port 7878)
- **SABnzbd**: linuxserver/sabnzbd:latest (port 8080)
- **NZBHydra2**: linuxserver/nzbhydra2:latest (port 5076)

### Current Volume Mounts
```
Sonarr:
  /docker/confs/docker-compose-usenet/sonarr:/config
  /nfs/docker/docker-compose-usenet:/downloads
  /nfs/Media/tv:/tv
  /nfs/Media/anime:/anime

Radarr:
  /docker/confs/docker-compose-usenet/radarr:/config
  /nfs/docker/docker-compose-usenet:/downloads
  /nfs/Media/movies:/movies
  /nfs/Media/anime:/anime

SABnzbd:
  /docker/confs/docker-compose-usenet/sabnzbd:/config
  /nfs/docker/docker-compose-usenet:/downloads
  /nfs/Media/movies:/movies
  /nfs/Media/tv:/tv

NZBHydra2:
  /docker/confs/docker-compose-usenet/nzbhydra2:/config
  /nfs/docker/docker-compose-usenet:/downloads
```

## K8s Target State

### Existing NFS PVCs (nfs-media StorageClass)
- **nfs-movies**: 192.168.1.200:/mnt/Arr1/SMB/pvc-xxx (maps to /nfs/Media/movies)
- **nfs-tv**: 192.168.1.200:/mnt/Arr1/SMB/pvc-xxx (maps to /nfs/Media/tv)
- **nfs-anime**: 192.168.1.200:/mnt/Arr1/SMB/pvc-xxx (maps to /nfs/Media/anime)
- **nfs-downloads**: 192.168.1.200:/mnt/Arr1/SMB/pvc-xxx (maps to /nfs/docker/docker-compose-usenet)

### Required New PVCs (longhorn StorageClass)
- **sonarr-config**: 5Gi (app config)
- **radarr-config**: 5Gi (app config)
- **sabnzbd-config**: 5Gi (app config)
- **nzbhydra2-config**: 2Gi (app config)

### Critical Path Mapping
**IMPORTANT**: Plex reads from these exact NFS paths. K8s apps MUST use same paths:
- Movies: `/movies` → nfs-movies PVC
- TV: `/tv` → nfs-tv PVC
- Anime: `/anime` → nfs-anime PVC
- Downloads: `/downloads` → nfs-downloads PVC

## Migration Steps

### 1. Create App Directories
```bash
cd /workspace/heezy-k8s/apps
mkdir -p sonarr radarr sabnzbd nzbhydra2
```

### 2. Create Manifests for Each Service
Each service needs:
- deployment.yaml (with proper NFS mounts)
- pvc.yaml (for config storage)
- service.yaml (ClusterIP for internal communication)

### 3. Service Connectivity Changes
After migration, services will communicate via K8s DNS:
- Sonarr → SABnzbd: `http://sabnzbd.heezy.svc.cluster.local:8080`
- Radarr → SABnzbd: `http://sabnzbd.heezy.svc.cluster.local:8080`
- Sonarr → NZBHydra2: `http://nzbhydra2.heezy.svc.cluster.local:5076`
- Radarr → NZBHydra2: `http://nzbhydra2.heezy.svc.cluster.local:5076`
- Overseerr → Sonarr: `http://sonarr.heezy.svc.cluster.local:8989`
- Overseerr → Radarr: `http://radarr.heezy.svc.cluster.local:7878`

### 4. Configuration Migration
Need to copy existing configs from 192.168.1.14:
```bash
# Backup configs from old server
ssh 192.168.1.14 "sudo tar -czf /tmp/media-configs.tar.gz \
  /docker/confs/docker-compose-usenet/sonarr \
  /docker/confs/docker-compose-usenet/radarr \
  /docker/confs/docker-compose-usenet/sabnzbd \
  /docker/confs/docker-compose-usenet/nzbhydra2"

# Copy to k8s node
scp 192.168.1.14:/tmp/media-configs.tar.gz /tmp/

# Extract to PVCs after pods are created
```

### 5. Update Overseerr Configuration
After migration, update Overseerr settings.json:
- Sonarr hostname: `192.168.1.14` → `sonarr.heezy.svc.cluster.local`
- Radarr hostname: `192.168.1.14` → `radarr.heezy.svc.cluster.local`

## Deployment Order
1. **SABnzbd** (download client - no dependencies)
2. **NZBHydra2** (indexer - no dependencies)
3. **Sonarr** (depends on SABnzbd, NZBHydra2)
4. **Radarr** (depends on SABnzbd, NZBHydra2)
5. **Update Overseerr** (depends on Sonarr, Radarr)

## Next Actions
- [ ] Create SABnzbd manifests
- [ ] Create NZBHydra2 manifests
- [ ] Create Sonarr manifests
- [ ] Create Radarr manifests
- [ ] Deploy services via GitHub Actions
- [ ] Migrate configuration data
- [ ] Update Overseerr connectivity
- [ ] Test end-to-end workflow
- [ ] Decommission old containers on 192.168.1.14

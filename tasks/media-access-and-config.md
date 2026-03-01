# Media Services Access & Config Migration

## Access Strategy

### Internal Access (K8s DNS)
- SABnzbd: `http://sabnzbd.heezy.svc.cluster.local:8080`
- NZBHydra2: `http://nzbhydra2.heezy.svc.cluster.local:5076`
- Sonarr: `http://sonarr.heezy.svc.cluster.local:8989`
- Radarr: `http://radarr.heezy.svc.cluster.local:7878`

### External Access via NodePort
Create NodePort services:
- SABnzbd: `http://192.168.1.15:30080`
- NZBHydra2: `http://192.168.1.15:30076`
- Sonarr: `http://192.168.1.15:30989`
- Radarr: `http://192.168.1.15:30878`

### Public Access via SWAG
Add SWAG proxy configs for:
- `sabnzbd.trentnielsen.me`
- `nzbhydra2.trentnielsen.me`
- `sonarr.trentnielsen.me`
- `radarr.trentnielsen.me`

## Config Migration Steps

1. Backup configs from 192.168.1.14:
```bash
ssh 192.168.1.14 "sudo tar -czf /tmp/media-configs.tar.gz -C /docker/confs/docker-compose-usenet sonarr radarr sabnzbd nzbhydra2"
scp 192.168.1.14:/tmp/media-configs.tar.gz /tmp/
```

2. Extract and copy to each pod:
```bash
tar -xzf /tmp/media-configs.tar.gz -C /tmp/
kubectl cp /tmp/sonarr heezy/sonarr-pod:/config
kubectl cp /tmp/radarr heezy/radarr-pod:/config
kubectl cp /tmp/sabnzbd heezy/sabnzbd-pod:/config
kubectl cp /tmp/nzbhydra2 heezy/nzbhydra2-pod:/config
```

3. Restart pods to load configs

4. Update service URLs in each app config

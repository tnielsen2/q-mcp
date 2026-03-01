# Media Services Access & Config Migration

## NodePort Access (192.168.1.15)
- SABnzbd: 30080
- NZBHydra2: 30076
- Sonarr: 30989
- Radarr: 30878

## Config Migration
1. Backup from 192.168.1.14:/docker/confs/docker-compose-usenet/
2. Copy to PVCs via kubectl cp
3. Restart pods
4. Update URLs to K8s service names

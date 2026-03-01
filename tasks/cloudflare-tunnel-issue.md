# Cloudflare Tunnel Issue

## Problem
Cloudflare Tunnel showing Error 1033 after migrating SWAG to Kubernetes.

## Root Cause
The tunnel `swagpipelineproxy` (UUID: 5fcecb9d-b718-44f3-8d8e-6c4021dff3d8) is trying to connect but getting "control stream encountered a failure while serving" errors.

## Tunnel Status
- Cloudflared is running in K8s pod
- Connecting to Cloudflare edge (198.41.200.23, 198.41.192.67)
- Authentication appears to work (no auth errors)
- Control stream failing - likely configuration issue

## Possible Causes
1. Tunnel configuration in Cloudflare dashboard still points to old server
2. Ingress rules in Cloudflare need to be updated
3. Tunnel may need to be recreated

## Solution Options

### Option 1: Update Cloudflare Dashboard (RECOMMENDED)
1. Login to Cloudflare dashboard
2. Go to Zero Trust > Access > Tunnels
3. Find tunnel `swagpipelineproxy`
4. Update Public Hostname configuration:
   - Hostname: *.trentnielsen.me, trentnielsen.me
   - Service: https://192.168.1.15:30428 (or use localhost:443 if tunnel is in cluster)
5. Save configuration

### Option 2: Recreate Tunnel
1. Delete old tunnel in Cloudflare dashboard
2. Create new tunnel
3. Get new credentials
4. Update K8s secrets
5. Redeploy

### Option 3: Use NodePort Directly (CURRENT WORKAROUND)
- SWAG is accessible via: https://192.168.1.15:30428
- Works without Cloudflare Tunnel
- Can configure DNS to point directly to NodePort
- Or setup port forwarding on router

## Current Workaround
SWAG is fully functional via NodePort:
- HTTPS: https://192.168.1.15:30428
- HTTP: http://192.168.1.15:32498

## Credentials
- Tunnel UUID: 5fcecb9d-b718-44f3-8d8e-6c4021dff3d8
- Tunnel Name: swagpipelineproxy
- Account ID: 22de8cf0d927ea0afcf5d3c844967da3
- Zone ID: 4d007e5bcbe0c7701788d7bf2a16c582
- Credentials file: /tmp/tunnel-credentials.json (in pod)

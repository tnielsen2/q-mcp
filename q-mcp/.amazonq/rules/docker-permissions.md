# Docker Container User Permissions

## Overview

Docker containers run with specific user/group IDs. Files mounted into containers must have correct ownership for the container user to access them.

## Problem: Permission Denied Errors

### Symptoms
- Container logs show "permission denied" when accessing mounted files
- Service discovery fails with "open /path/to/file: permission denied"
- Application cannot read configuration files

### Root Cause
Files created on the host are owned by root (UID 0) by default, but containers often run as non-root users for security.

## Common Container Users

| Service | User:Group | UID:GID |
|---------|------------|---------|
| Prometheus | nobody:nobody | 65534:65534 or 1000:1000 |
| Grafana | grafana | 472:472 or 1000:1000 |
| Loki | loki | 10001:10001 or 1000:1000 |
| Most LinuxServer.io images | abc | 1000:1000 |

## Solution: Set Correct Ownership

### In Ansible Tasks

Always specify `owner` and `group` when copying files that will be mounted into containers:

```yaml
- name: Copy config file
  copy:
    src: /tmp/config-file
    dest: /etc/service/config
    mode: '0600'
    owner: "1000"
    group: "1000"
```

### For Directories

```yaml
- name: Create config directory
  file:
    path: /opt/service/config
    state: directory
    mode: '0755'
    owner: "1000"
    group: "1000"
    recurse: yes
```

## Case Study: Prometheus Kubeconfig Permission Denied

### Problem
Prometheus couldn't discover Kubernetes nodes:
```
Cannot create service discovery: error loading config file "/etc/prometheus/kubeconfig": 
open /etc/prometheus/kubeconfig: permission denied
```

### Root Cause
1. Kubeconfig was copied to `/etc/prometheus/kubeconfig` on host
2. File owned by root:root with mode 0600
3. Prometheus container runs as user 1000:1000
4. Container couldn't read the file

### Solution
```yaml
- name: Copy kubeconfig to prometheus config dir
  copy:
    src: /tmp/kubeconfig-prometheus
    dest: /etc/prometheus/kubeconfig
    mode: '0600'
    owner: "1000"
    group: "1000"
```

### Verification
```bash
# On host
ls -la /etc/prometheus/kubeconfig
# Should show: -rw------- 1 1000 1000 5466 ...

# In container
docker exec prometheus ls -la /etc/prometheus/kubeconfig
# Should show: -rw------- 1 nobody nobody 5466 ...
```

## Docker Compose User Specification

When running containers with docker-compose, specify the user:

```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    user: "1000:1000"
    volumes:
      - /etc/prometheus/kubeconfig:/etc/prometheus/kubeconfig:ro
```

The `:ro` flag makes the mount read-only for additional security.

## Debugging Permission Issues

### Check File Ownership on Host
```bash
ls -la /path/to/mounted/file
```

### Check Container User
```bash
docker exec <container> id
# Shows: uid=1000 gid=1000 groups=1000
```

### Check File Ownership in Container
```bash
docker exec <container> ls -la /path/to/file
```

### Check Container Logs
```bash
docker logs <container> 2>&1 | grep -i "permission\|denied"
```

## Best Practices

1. **Always specify owner/group** when creating files for containers
2. **Use numeric UIDs** (1000) instead of names (abc) for portability
3. **Match container user** - check Dockerfile or image docs for USER directive
4. **Use read-only mounts** (`:ro`) when container doesn't need write access
5. **Set minimal permissions** - 0600 for secrets, 0644 for configs, 0755 for directories
6. **Test after deployment** - verify container can access files

## Common Mistakes

### 1. Forgetting Owner/Group
❌ **Wrong:**
```yaml
- name: Copy config
  copy:
    src: config.yml
    dest: /etc/service/config.yml
    mode: '0644'
```

✅ **Correct:**
```yaml
- name: Copy config
  copy:
    src: config.yml
    dest: /etc/service/config.yml
    mode: '0644'
    owner: "1000"
    group: "1000"
```

### 2. Using Root Ownership
❌ **Wrong:**
```yaml
owner: "root"
group: "root"
```

✅ **Correct:**
```yaml
owner: "1000"  # Match container user
group: "1000"
```

### 3. Wrong Permissions
❌ **Wrong:**
```yaml
mode: '0644'  # Too permissive for secrets
```

✅ **Correct:**
```yaml
mode: '0600'  # Only owner can read secrets
```

## Summary

When mounting files into Docker containers:

1. ✅ Check container's USER directive or default user
2. ✅ Set owner/group to match container user (usually 1000:1000)
3. ✅ Use appropriate permissions (0600 for secrets, 0644 for configs)
4. ✅ Use read-only mounts (`:ro`) when possible
5. ✅ Verify access after deployment
6. ✅ Check logs for "permission denied" errors

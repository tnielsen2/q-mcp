# Kubernetes Cheat Sheet - Heezy Cluster

## Cluster Info
- **Nodes**: nebula-1 through nebula-5 (192.168.1.15-19)
- **Control Plane**: nebula-1
- **Namespace**: heezy
- **Kubeconfig**: ~/.kube/heezy-config

## Quick Status Checks

```bash
# Cluster nodes
kubectl get nodes

# All resources in heezy namespace
kubectl get all -n heezy

# Pods with node placement
kubectl get pods -n heezy -o wide

# Storage
kubectl get pvc -n heezy
kubectl get sc
```

## Pod Management

```bash
# Get pods
kubectl get pods -n heezy
kubectl get pods -n heezy -l app=swag

# Pod details
kubectl describe pod -n heezy <pod-name>
kubectl describe pod -n heezy -l app=swag

# Logs
kubectl logs -n heezy <pod-name>
kubectl logs -n heezy <pod-name> --tail=50
kubectl logs -n heezy <pod-name> -f  # follow
kubectl logs -n heezy -l app=swag --tail=100

# Execute commands in pod
kubectl exec -n heezy <pod-name> -- <command>
kubectl exec -n heezy <pod-name> -it -- /bin/bash

# Restart pod
kubectl delete pod -n heezy <pod-name>
kubectl rollout restart deployment -n heezy <deployment-name>
```

## Deployments

```bash
# Get deployments
kubectl get deployment -n heezy
kubectl get deployment -n heezy swag

# Deployment details
kubectl describe deployment -n heezy <deployment-name>

# Scale deployment
kubectl scale deployment -n heezy <deployment-name> --replicas=3

# Update image
kubectl set image deployment -n heezy <deployment-name> <container>=<new-image>

# Rollout status
kubectl rollout status deployment -n heezy <deployment-name>
kubectl rollout history deployment -n heezy <deployment-name>
kubectl rollout undo deployment -n heezy <deployment-name>
```

## Services

```bash
# Get services
kubectl get svc -n heezy
kubectl get svc -n heezy swag

# Service details
kubectl describe svc -n heezy <service-name>

# Get endpoints
kubectl get endpoints -n heezy
```

## ConfigMaps & Secrets

```bash
# ConfigMaps
kubectl get configmap -n heezy
kubectl describe configmap -n heezy <name>
kubectl get configmap -n heezy <name> -o yaml

# Secrets
kubectl get secret -n heezy
kubectl describe secret -n heezy <name>
kubectl get secret -n heezy <name> -o yaml
```

## Storage

```bash
# PVCs
kubectl get pvc -n heezy
kubectl describe pvc -n heezy <pvc-name>

# PVs
kubectl get pv

# Storage Classes
kubectl get sc
```

## Apply/Delete Resources

```bash
# Apply manifests
kubectl apply -f <file.yaml>
kubectl apply -f <directory>/

# Delete resources
kubectl delete -f <file.yaml>
kubectl delete pod -n heezy <pod-name>
kubectl delete deployment -n heezy <deployment-name>

# Force delete stuck pod
kubectl delete pod -n heezy <pod-name> --force --grace-period=0
```

## Debugging

```bash
# Events
kubectl get events -n heezy --sort-by='.lastTimestamp'
kubectl get events -n heezy --field-selector involvedObject.name=<pod-name>

# Resource usage
kubectl top nodes
kubectl top pods -n heezy

# Port forward
kubectl port-forward -n heezy <pod-name> 8080:80

# Copy files
kubectl cp <local-file> heezy/<pod-name>:/path/in/pod
kubectl cp heezy/<pod-name>:/path/in/pod <local-file>

# Describe all resources
kubectl describe all -n heezy
```

## Labels & Selectors

```bash
# Get by label
kubectl get pods -n heezy -l app=swag
kubectl get all -n heezy -l app=swag

# Show labels
kubectl get pods -n heezy --show-labels

# Add label
kubectl label pod -n heezy <pod-name> env=production

# Remove label
kubectl label pod -n heezy <pod-name> env-
```

## Namespace Operations

```bash
# List namespaces
kubectl get namespaces

# Create namespace
kubectl create namespace <name>

# Set default namespace
kubectl config set-context --current --namespace=heezy
```

## YAML Output

```bash
# Get resource as YAML
kubectl get pod -n heezy <pod-name> -o yaml
kubectl get deployment -n heezy <deployment-name> -o yaml

# Get without managed fields
kubectl get pod -n heezy <pod-name> -o yaml --export

# JSON output
kubectl get pod -n heezy <pod-name> -o json
```

## Heezy-Specific Commands

### SWAG Service
```bash
# Status
kubectl get all -n heezy | grep swag
kubectl get pod -n heezy -l app=swag -o wide
kubectl logs -n heezy -l app=swag --tail=50

# Tunnel status
kubectl logs -n heezy -l app=swag | grep "Registered tunnel"

# Certificate status
kubectl logs -n heezy -l app=swag | grep -i certificate

# Restart
kubectl delete pod -n heezy -l app=swag
```

### Storage Classes
```bash
# Available storage
kubectl get sc

# Longhorn (default)
kubectl get pvc -n heezy | grep longhorn

# NFS media storage
kubectl get pvc -n heezy | grep nfs-media
```

### ECR Credentials
```bash
# Check ECR secret
kubectl get secret -n heezy ecr-credentials
kubectl describe secret -n heezy ecr-credentials
```

## Common Patterns

### Check if deployment is healthy
```bash
kubectl get deployment -n heezy <name> && \
kubectl get pods -n heezy -l app=<name> && \
kubectl logs -n heezy -l app=<name> --tail=20
```

### Full service status
```bash
kubectl get deployment,pod,svc,pvc -n heezy -l app=<name>
```

### Watch resources
```bash
kubectl get pods -n heezy -w
kubectl get events -n heezy -w
```

### Get pod on specific node
```bash
kubectl get pods -n heezy -o wide | grep nebula-5
```

## Useful Aliases

Add to ~/.bashrc or ~/.zshrc:
```bash
alias k='kubectl'
alias kgp='kubectl get pods -n heezy'
alias kgpw='kubectl get pods -n heezy -o wide'
alias kgs='kubectl get svc -n heezy'
alias kgd='kubectl get deployment -n heezy'
alias kl='kubectl logs -n heezy'
alias kx='kubectl exec -n heezy -it'
alias kd='kubectl describe -n heezy'
alias ka='kubectl apply -f'
alias kdel='kubectl delete -n heezy'
```

## Emergency Commands

```bash
# Restart all pods in deployment
kubectl rollout restart deployment -n heezy <name>

# Force delete stuck resources
kubectl delete pod -n heezy <name> --force --grace-period=0

# Get all failing pods
kubectl get pods -n heezy --field-selector=status.phase!=Running

# Check node resources
kubectl describe node <node-name> | grep -A 5 "Allocated resources"
```

## Access URLs

- **SWAG HTTPS**: https://192.168.1.15:30428 (NodePort)
- **SWAG HTTP**: http://192.168.1.15:32498 (NodePort)
- **Cloudflare Tunnel**: https://about.trentnielsen.me

#!/bin/bash
# Setup task: heezy-k8s repository

set -e

REPO_DIR="/workspace/heezy-k8s"

echo "=== heezy-k8s Setup ==="

# Pull latest changes
cd $REPO_DIR
git pull origin main

# Show current state
echo "Current branch: $(git branch --show-current)"
echo "Latest commit: $(git log -1 --oneline)"

# List apps
echo -e "\nDeployed apps:"
ls -1 apps/ | grep -v "^_"

# Show base resources
echo -e "\nBase resources:"
ls -1 base/

# Check workflows
echo -e "\nWorkflows:"
ls -1 .github/workflows/

echo -e "\n✓ heezy-k8s ready"

#!/bin/bash
# Setup task: ansible-heezy repository

set -e

REPO_DIR="/workspace/ansible-heezy"

echo "=== ansible-heezy Setup ==="

# Pull latest changes
cd $REPO_DIR
git pull origin main

# Show current state
echo "Current branch: $(git branch --show-current)"
echo "Latest commit: $(git log -1 --oneline)"

# List roles
echo -e "\nAvailable roles:"
ls -1 roles/

# List playbooks
echo -e "\nAvailable playbooks:"
ls -1 playbooks/

# Show inventory
echo -e "\nInventory groups:"
grep -E "^\[.*\]$" inventory/hosts.yml || echo "Using YAML inventory"

# Check workflows
echo -e "\nWorkflows:"
ls -1 .github/workflows/ | grep -E "^playbook-.*\.yml$"

echo -e "\n✓ ansible-heezy ready"

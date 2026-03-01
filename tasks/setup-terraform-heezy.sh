#!/bin/bash
# Setup task: terraform-heezy repository

set -e

REPO_DIR="/workspace/terraform-heezy"

echo "=== terraform-heezy Setup ==="

# Pull latest changes
cd $REPO_DIR
git pull origin main

# Show current state
echo "Current branch: $(git branch --show-current)"
echo "Latest commit: $(git log -1 --oneline)"

# Show structure
echo -e "\nEnvironments:"
find environments -name "*.tf" -type f | head -10

# Check for terraform state
echo -e "\nTerraform state files:"
find . -name "terraform.tfstate" -o -name "*.tfstate.backup" | head -5

echo -e "\n✓ terraform-heezy ready"

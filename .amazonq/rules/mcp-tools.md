# MCP Tools Usage Rules

## Available MCP Tools

You have access to the following MCP tools running in the `mcp-tools` Docker container:

- **heezy___fs_read** - Read file contents from `/workspace`
- **heezy___fs_write** - Write file contents to `/workspace`
- **heezy___fs_list** - List directory contents in `/workspace`
- **heezy___shell** - Execute shell commands inside the container
- **heezy___terraform** - Run Terraform commands (e.g., `init`, `plan`, `apply`, `destroy`)
- **heezy___gh** - Run GitHub CLI commands (e.g., `repo list`, `pr create`, `issue list`)
- **heezy___aws** - Run AWS CLI commands (e.g., `s3 ls`, `ec2 describe-instances`)
- **heezy___kubectl** - Run kubectl commands for k8s cluster management
- **heezy___ssh** - SSH to remote hosts (requires host, command, optional user)
- **heezy___gh_poll** - Poll GitHub Actions runs until completion (non-blocking)

don't ever ask to run docker exec in my local project or workspace, you use what you have at your disposal and if you
need something, you add it here. 

## Tool Usage Guidelines

### File Operations
- All file paths are relative to `/workspace` inside the container
- `/workspace` maps to the project root directory on the host
- Use `heezy___fs_read` and `heezy___fs_write` for file operations instead of shell commands when possible

### AWS Operations
- AWS credentials are mounted from `~/.aws` (read-only)
- Set AWS profile using: `export AWS_DEFAULT_PROFILE=<profile-name>` in shell commands
- Always include profile export when chaining AWS commands
- **CRITICAL: MCP has READ-ONLY AWS access only** - Use `mcp-readonly` service account
- **NEVER run destructive AWS commands** - No create, delete, modify, terminate operations
- **Allowed AWS operations**: describe, list, get commands only for resource inspection
- **Code-first approach**: Update Terraform/CloudFormation code, never direct AWS changes

### GitHub Operations
- GitHub credentials are mounted from `~/.config/gh` (read-only)
- Use `heezy___gh` tool for GitHub API operations
- Authenticate on host with `gh auth login` before using

### Terraform Operations
- Use `-chdir=/workspace` flag for Terraform commands when needed
- Always run `terraform init` before other Terraform commands
- Use `terraform validate` to check syntax without credentials

### Shell Commands
- Use `shell` tool for complex operations requiring multiple commands
- Chain commands with `&&` for sequential execution
- Export environment variables in the same command where they're used

## Best Practices

1. **Prefer MCP tools over executeBash** - Use the specialized heezy___ prefixed MCP tools instead of docker exec commands
2. **Check authentication** - Verify AWS/GitHub auth before making API calls
3. **Use absolute paths** - Always use `/workspace` prefix for file operations
4. **Chain related commands** - Combine environment setup and execution in single shell commands
5. **Handle errors gracefully** - Check tool responses for errors before proceeding
6. **Never use blocking/watch commands** - Commands like `gh run watch`, `kubectl ... --watch`, or anything that streams/blocks will cause the Q plugin to time out. Poll with `gh run list` or `kubectl get` via `executeBash` as a fallback instead.
7. **Use executeBash as fallback** - If an MCP tool call times out or fails, fall back to `executeBash` with `docker exec -i mcp-tools node /mcp/mcp-server.js` to invoke the tool directly


## Heezy Project Workflow

### Status Tracking
- Write status updates to `/workspace/tasks/status.md`
- Document progress, blockers, and next steps
- Update after significant operations

### Repository Setup
- Setup scripts in `/workspace/tasks/setup-*.sh`
- Always pull latest changes before operations
- Review README files to understand operations

### ansible-heezy Operations
- **NEVER run Ansible locally** - always via GitHub Actions
- Workflow: Edit roles/playbooks → Commit → Push → GitHub Actions runs playbooks
- Playbooks execute in Docker container on self-hosted runner
- Changes trigger workflows automatically based on paths
- Manual trigger: `gh workflow run "Playbook <Name> Execution" --repo tnielsen2/ansible-heezy`

### terraform-heezy Operations
- Structure: `environments/{production,dev,shared}/{heezy,aws}`
- **NEVER run terraform apply** - only GitHub Actions runner executes apply
- Workflow: Edit terraform → Commit → Push → Trigger workflow → Poll for completion
- Use `terraform plan` and `terraform validate` for local testing only

### heezy-k8s Operations
- Application manifests for 5-node MicroK8s cluster (192.168.1.15-19)
- **NEVER run kubectl apply** - only GitHub Actions deploys manifests
- Workflow: Edit manifests → Commit → Push → GitHub Actions deploys automatically
- Push to main branch triggers auto-deploy via GitHub Actions
- kubectl access for diagnostics only (get, describe, logs)
- Storage: Longhorn (default) + NFS (nfs-media)

### SSH Access to Hosts
- Default user: `mcp-admin` (set as default in server, no need to specify)
- Key: `/root/.ssh/mcp_heezy` (automatically used by server)
- K8s hosts: 192.168.1.15-19 (nebula-1 through nebula-5)
- big-boi: 192.168.1.21
- Provisioned by ansible-heezy mcp-access role

### Polling GitHub Actions Runs
- Use `heezy___gh_poll` tool instead of `gh run watch` to avoid Q plugin timeouts
- `heezy___gh_poll` takes `repo` (e.g. `tnielsen2/ansible-heezy`) and `run_id`
- Polls every 5s, times out after 10 minutes, returns final conclusion

# MCP Tools Usage Rules

## Available MCP Tools

You have access to the following MCP tools running in the `mcp-tools` Docker container:

- **fs_read** - Read file contents from `/workspace`
- **fs_write** - Write file contents to `/workspace`
- **fs_list** - List directory contents in `/workspace`
- **shell** - Execute shell commands inside the container
- **terraform** - Run Terraform commands (e.g., `init`, `plan`, `apply`, `destroy`)
- **gh** - Run GitHub CLI commands (e.g., `repo list`, `pr create`, `issue list`)
- **aws** - Run AWS CLI commands (e.g., `s3 ls`, `ec2 describe-instances`)

## Tool Usage Guidelines

### File Operations
- All file paths are relative to `/workspace` inside the container
- `/workspace` maps to the project root directory on the host
- Use `fs_read` and `fs_write` for file operations instead of shell commands when possible

### AWS Operations
- AWS credentials are mounted from `~/.aws` (read-only)
- Set AWS profile using: `export AWS_DEFAULT_PROFILE=<profile-name>` in shell commands
- Always include profile export when chaining AWS commands

### GitHub Operations
- GitHub credentials are mounted from `~/.config/gh` (read-only)
- Use `gh` tool for GitHub API operations
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

1. **Prefer MCP tools over executeBash** - Use the specialized MCP tools instead of docker exec commands
2. **Check authentication** - Verify AWS/GitHub auth before making API calls
3. **Use absolute paths** - Always use `/workspace` prefix for file operations
4. **Chain related commands** - Combine environment setup and execution in single shell commands
5. **Handle errors gracefully** - Check tool responses for errors before proceeding

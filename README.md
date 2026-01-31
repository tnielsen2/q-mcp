# MCP Docker Server

MCP server with Terraform, GitHub CLI, AWS CLI, and filesystem tools.

## Setup

### Prerequisites

1. **Authenticate with AWS:**
   ```bash
   aws sso login --profile <your-profile>
   export AWS_DEFAULT_PROFILE=<your-profile>
   ```

2. **Authenticate with GitHub:**
   ```bash
   gh auth login
   ```

### Start the Server

1. **Build and start the container:**
   ```bash
   docker-compose up -d --build
   ```

2. **Verify it's running:**
   ```bash
   docker ps | grep mcp-tools
   ```

## IDE Integration

The agent configuration is in `.amazonq/agents/docker-mcp.json`. 

To use it in your IDE:
- The MCP server runs inside the `mcp-tools` container
- AWS credentials are mounted from `~/.aws` (read-only) - must run `aws sso login` on host
- GitHub credentials are mounted from `~/.config/gh` (read-only) - must run `gh auth login` on host
- Working directory is mounted at `/workspace`

## Available Tools

- **fs_read** - Read files
- **fs_write** - Write files  
- **fs_list** - List directory contents
- **shell** - Run shell commands
- **terraform** - Run terraform commands
- **gh** - Run GitHub CLI commands
- **aws** - Run AWS CLI commands

## Usage Examples

```bash
# Test the server manually
docker exec -i mcp-tools node /mcp/mcp-server.js

# Run terraform
docker exec mcp-tools terraform version

# Run AWS CLI
docker exec mcp-tools aws s3 ls

# Run GitHub CLI
docker exec mcp-tools gh --version
```

## Stop

```bash
docker-compose down
```

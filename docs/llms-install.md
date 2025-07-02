# Prometheus MCP Server Installation Guide for LLMs

This guide will help you install and configure the Prometheus MCP Server for monitoring and metrics operations through Claude Desktop and other AI assistants.

## Requirements

- Docker installed on your system
- Access to a Prometheus server instance
- Valid Prometheus credentials (if authentication is required)
- Web browser for testing (optional)

## Installation Methods

### Method 1: Docker with Environment Variables (Single User) - **DEVELOPMENT**

**Best for**: Single user, production deployment, isolated environment

**Step 1**: Pull Docker image
```bash
docker pull ghcr.io/olegische/prometheus-mcp-multi-user:0.1.0
```

**Step 2**: Configure Claude Desktop
```json
{
  "mcpServers": {
    "prometheus": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-e", "PROMETHEUS_URL",
        "-e", "PROMETHEUS_USERNAME", 
        "-e", "PROMETHEUS_PASSWORD",
        "-e", "PROMETHEUS_TOKEN",
        "-e", "ORG_ID",
        "ghcr.io/olegische/prometheus-mcp-multi-user:0.1.0"
      ],
      "env": {
        "PROMETHEUS_URL": "http://your-prometheus-server:9090",
        "PROMETHEUS_USERNAME": "your_username",
        "PROMETHEUS_PASSWORD": "your_password"
      }
    }
  }
}
```

**For Bearer Token Authentication:**
```json
{
  "mcpServers": {
    "prometheus": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-e", "PROMETHEUS_URL",
        "-e", "PROMETHEUS_TOKEN",
        "-e", "ORG_ID",
        "ghcr.io/olegische/prometheus-mcp-multi-user:0.1.0"
      ],
      "env": {
        "PROMETHEUS_URL": "http://your-prometheus-server:9090",
        "PROMETHEUS_TOKEN": "your_bearer_token",
        "ORG_ID": "your_org_id"
      }
    }
  }
}
```

---

### Method 2: Docker with Custom Headers (Multi-User) - **RECOMMENDED**

**Best for**: Multi-user environments, enterprise deployments, dynamic credentials

**Step 1**: Start Docker container with custom headers support
```bash
docker run --rm -p 8660:8660 \
  -e TRANSPORT=sse \
  -e PORT=8660 \
  -e HOST=0.0.0.0 \
  -e MCP_CREDENTIALS_PASSTHROUGH=true \
  -e PROMETHEUS_VERIFY_SSL=false \
  ghcr.io/olegische/prometheus-mcp-multi-user:0.1.0
```

**Step 2**: Configure Claude Desktop with SSE transport
```json
{
  "mcpServers": {
    "prometheus": {
      "type": "sse",
      "url": "http://host.docker.internal:8660/sse",
      "headers": {
        "X-Prometheus-URL": "http://your-prometheus-url:9090",
        "X-Prometheus-Token": "your-prometheus-token",
        "X-Scope-OrgID": "your-org-id",
        "X-Prometheus-Verify-SSL": "true"
      }
    }
  }
}
```

**For Basic Authentication:**
```json
{
  "mcpServers": {
    "prometheus": {
      "type": "sse",
      "url": "http://host.docker.internal:8660/sse",
      "headers": {
        "X-Prometheus-URL": "http://your-prometheus-url:9090",
        "X-Prometheus-Username": "your_username",
        "X-Prometheus-Password": "your_password",
        "X-Scope-OrgID": "your-org-id",
        "X-Prometheus-Verify-SSL": "true"
      }
    }
  }
}
```

**For Self-Signed Certificates:**
```json
{
  "mcpServers": {
    "prometheus": {
      "type": "sse",
      "url": "http://host.docker.internal:8660/sse",
      "headers": {
        "X-Prometheus-URL": "https://your-prometheus-url:9090",
        "X-Prometheus-Token": "your-prometheus-token",
        "X-Scope-OrgID": "your-org-id",
        "X-Prometheus-Verify-SSL": "false"
      }
    }
  }
}
```

---

### Method 3: Docker Compose Production Deployment

**Best for**: Production environments, persistent deployments

**Step 1**: Create docker-compose.yml
```yaml
services:
  prometheus-mcp:
    image: ghcr.io/olegische/prometheus-mcp-multi-user:0.1.0
    container_name: prometheus-mcp
    platform: linux/amd64
    ports:
      - "8660:8660"
    environment:
      - TRANSPORT=sse
      - PORT=8660
      - HOST=0.0.0.0
      - PROMETHEUS_VERIFY_SSL=false
      - MCP_CREDENTIALS_PASSTHROUGH=true
    restart: unless-stopped
    volumes:
      - ${HOME}/.prometheus-mcp:/home/app/.prometheus-mcp
```

**Step 2**: Start the service
```bash
docker-compose up -d
```

**Step 3**: Configure Claude Desktop
```json
{
  "mcpServers": {
    "prometheus": {
      "type": "sse",
      "url": "http://host.docker.internal:8660/sse",
      "headers": {
        "X-Prometheus-URL": "http://your-prometheus-url:9090",
        "X-Prometheus-Token": "your-prometheus-token",
        "X-Scope-OrgID": "your-org-id"
      }
    }
  }
}
```

---

### Method 4: MCPO Proxy for OpenWebUI Integration

**Best for**: OpenWebUI integration, REST API access, web-based AI interfaces

MCPO (MCP-to-OpenAPI proxy) converts MCP servers into standard REST APIs, making them compatible with OpenWebUI and other web-based AI platforms.

**Step 1**: Start MCP server with custom headers
```bash
docker run --rm -p 8660:8660 \
  -e TRANSPORT=sse \
  -e PORT=8660 \
  -e HOST=0.0.0.0 \
  -e MCP_CREDENTIALS_PASSTHROUGH=true \
  -e PROMETHEUS_VERIFY_SSL=false \
  ghcr.io/olegische/prometheus-mcp-multi-user:0.1.0
```

**Step 2**: Set up environment variables for MCPO
```bash
# For Bearer Token authentication
export HTTP_HEADER_PROMETHEUS_URL="http://your-prometheus-server:9090"
export HTTP_HEADER_PROMETHEUS_TOKEN="your_bearer_token"
export HTTP_HEADER_SCOPE_ORGID="your_org_id"
export HTTP_HEADER_PROMETHEUS_VERIFY_SSL="true"

# For Basic authentication
export HTTP_HEADER_PROMETHEUS_URL="http://your-prometheus-server:9090"
export HTTP_HEADER_PROMETHEUS_USERNAME="your_username"
export HTTP_HEADER_PROMETHEUS_PASSWORD="your_password"
export HTTP_HEADER_SCOPE_ORGID="your_org_id"
export HTTP_HEADER_PROMETHEUS_VERIFY_SSL="true"

# For self-signed certificates
export HTTP_HEADER_PROMETHEUS_URL="https://your-prometheus-server:9090"
export HTTP_HEADER_PROMETHEUS_TOKEN="your_bearer_token"
export HTTP_HEADER_SCOPE_ORGID="your_org_id"
export HTTP_HEADER_PROMETHEUS_VERIFY_SSL="false"
```

**Step 3**: Run MCPO proxy to convert MCP to REST API
```bash
# For Bearer Token authentication
uvx mcpo --port 8600 --server-type "sse" \
    --header "{
        \"X-Prometheus-URL\": \"${HTTP_HEADER_PROMETHEUS_URL}\",
        \"X-Prometheus-Token\": \"${HTTP_HEADER_PROMETHEUS_TOKEN}\",
        \"X-Scope-OrgID\": \"${HTTP_HEADER_SCOPE_ORGID}\",
        \"X-Prometheus-Verify-SSL\": \"${HTTP_HEADER_PROMETHEUS_VERIFY_SSL}\"
    }" \
    -- http://host.docker.internal:8660/sse

# For Basic authentication
uvx mcpo --port 8600 --server-type "sse" \
    --header "{
        \"X-Prometheus-URL\": \"${HTTP_HEADER_PROMETHEUS_URL}\",
        \"X-Prometheus-Username\": \"${HTTP_HEADER_PROMETHEUS_USERNAME}\",
        \"X-Prometheus-Password\": \"${HTTP_HEADER_PROMETHEUS_PASSWORD}\",
        \"X-Scope-OrgID\": \"${HTTP_HEADER_SCOPE_ORGID}\",
        \"X-Prometheus-Verify-SSL\": \"${HTTP_HEADER_PROMETHEUS_VERIFY_SSL}\"
    }" \
    -- http://host.docker.internal:8660/sse

# For self-signed certificates
uvx mcpo --port 8600 --server-type "sse" \
    --header "{
        \"X-Prometheus-URL\": \"${HTTP_HEADER_PROMETHEUS_URL}\",
        \"X-Prometheus-Token\": \"${HTTP_HEADER_PROMETHEUS_TOKEN}\",
        \"X-Scope-OrgID\": \"${HTTP_HEADER_SCOPE_ORGID}\",
        \"X-Prometheus-Verify-SSL\": \"${HTTP_HEADER_PROMETHEUS_VERIFY_SSL}\"
    }" \
    -- http://host.docker.internal:8660/sse
```

---

## Authentication Setup

### For Prometheus with Basic Authentication

If your Prometheus server requires basic authentication:

```json
{
  "env": {
    "PROMETHEUS_URL": "http://your-prometheus-server:9090",
    "PROMETHEUS_USERNAME": "your_username",
    "PROMETHEUS_PASSWORD": "your_password",
    "PROMETHEUS_VERIFY_SSL": "true"
  }
}
```

Or with headers:
```json
{
  "headers": {
    "X-Prometheus-URL": "http://your-prometheus-server:9090",
    "X-Prometheus-Username": "your_username",
    "X-Prometheus-Password": "your_password",
    "X-Prometheus-Verify-SSL": "true"
  }
}
```

### For Prometheus with Bearer Token

If your Prometheus server uses bearer token authentication:

```json
{
  "env": {
    "PROMETHEUS_URL": "http://your-prometheus-server:9090",
    "PROMETHEUS_TOKEN": "your_bearer_token",
    "PROMETHEUS_VERIFY_SSL": "true"
  }
}
```

Or with headers:
```json
{
  "headers": {
    "X-Prometheus-URL": "http://your-prometheus-server:9090",
    "X-Prometheus-Token": "your_bearer_token",
    "X-Prometheus-Verify-SSL": "true"
  }
}
```

### For Multi-Tenant Prometheus (with Org ID)

If you're using a multi-tenant Prometheus setup (like Grafana Cloud or Cortex):

```json
{
  "env": {
    "PROMETHEUS_URL": "http://your-prometheus-server:9090",
    "PROMETHEUS_TOKEN": "your_bearer_token",
    "ORG_ID": "your_org_id",
    "PROMETHEUS_VERIFY_SSL": "true"
  }
}
```

Or with headers:
```json
{
  "headers": {
    "X-Prometheus-URL": "http://your-prometheus-server:9090",
    "X-Prometheus-Token": "your_bearer_token",
    "X-Scope-OrgID": "your_org_id",
    "X-Prometheus-Verify-SSL": "true"
  }
}
```

### For Self-Signed Certificates

If your Prometheus server uses self-signed certificates:

```json
{
  "env": {
    "PROMETHEUS_URL": "https://your-prometheus-server:9090",
    "PROMETHEUS_TOKEN": "your_bearer_token",
    "PROMETHEUS_VERIFY_SSL": "false"
  }
}
```

Or with headers:
```json
{
  "headers": {
    "X-Prometheus-URL": "https://your-prometheus-server:9090",
    "X-Prometheus-Token": "your_bearer_token",
    "X-Prometheus-Verify-SSL": "false"
  }
}
```

---

## IDE Configuration

### Claude Desktop Configuration Files

**For Claude Desktop**, edit the configuration file:
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

**For Cursor**: Open Settings → MCP → + Add new global MCP server

### Single Environment Configurations

**For development/testing only:**
```json
{
  "mcpServers": {
    "prometheus": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "-e", "PROMETHEUS_URL=http://localhost:9090",
        "ghcr.io/olegische/prometheus-mcp-multi-user:0.1.0"
      ]
    }
  }
}
```

**For production with SSL verification disabled:**
```json
{
  "mcpServers": {
    "prometheus": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "-e", "PROMETHEUS_URL",
        "-e", "PROMETHEUS_TOKEN",
        "-e", "PROMETHEUS_VERIFY_SSL=false",
        "ghcr.io/olegische/prometheus-mcp-multi-user:0.1.0"
      ],
      "env": {
        "PROMETHEUS_URL": "https://your-prometheus-server:9090",
        "PROMETHEUS_TOKEN": "your_token"
      }
    }
  }
}
```

---

## Configuration Options

### Environment Variables

- `PROMETHEUS_URL`: Prometheus server URL (required)
- `PROMETHEUS_USERNAME`: Username for basic auth (optional)
- `PROMETHEUS_PASSWORD`: Password for basic auth (optional)
- `PROMETHEUS_TOKEN`: Bearer token for token auth (optional)
- `ORG_ID`: Organization ID for multi-tenant setups (optional)
- `PROMETHEUS_VERIFY_SSL`: Set to "false" for self-signed certificates (default: true)
- `MCP_CREDENTIALS_PASSTHROUGH`: Enable header-based credentials (default: false)
- `TRANSPORT`: Transport type - "stdio" or "sse" (default: stdio)
- `HOST`: Host to bind to for SSE transport (default: 0.0.0.0)
- `PORT`: Port to bind to for SSE transport (default: 8660)

### Header-based Configuration (Passthrough Mode)

When `MCP_CREDENTIALS_PASSTHROUGH=true`, the following headers are supported:

- `X-Prometheus-URL`: Prometheus server URL (required)
- `X-Prometheus-Username`: Username for basic auth
- `X-Prometheus-Password`: Password for basic auth
- `X-Prometheus-Token`: Bearer token for token auth
- `X-Scope-OrgID`: Organization ID for multi-tenant setups
- `X-Prometheus-Verify-SSL`: Set to "false" for self-signed certificates (default: true)

---

## Troubleshooting

### Authentication Errors

- **Basic Auth**: Verify username and password are correct
- **Bearer Token**: Check token validity and expiration
- **Multi-tenant**: Ensure Org ID is correct and you have access

### Connection Issues

- Verify Prometheus URL is accessible from your machine
- Check firewall and network restrictions
- For self-signed certificates: Set `PROMETHEUS_VERIFY_SSL=false`
- For Docker networking: Use `host.docker.internal` instead of `localhost`

### Permission Errors

- Ensure your credentials have sufficient permissions to query Prometheus
- Check Prometheus server logs for authentication failures
- Verify API endpoints are enabled on your Prometheus server

### Debugging Commands

```bash
# Test Docker image
docker run --rm ghcr.io/olegische/prometheus-mcp-multi-user:0.1.0 --help

# Check container logs
docker logs prometheus-mcp

# Test Prometheus connectivity
curl -H "Authorization: Bearer your_token" \
     "http://your-prometheus-server:9090/api/v1/query?query=up"

# Check logs (macOS)
tail -n 20 -f ~/Library/Logs/Claude/mcp*.log

# Check logs (Windows)
type %APPDATA%\Claude\logs\mcp*.log | more
```

---

## Available Tools

The Prometheus MCP Server provides the following tools:

### execute_query
Execute a PromQL instant query against Prometheus
- **query**: PromQL query string
- **time**: Optional RFC3339 or Unix timestamp (default: current time)

### execute_range_query
Execute a PromQL range query with start time, end time, and step interval
- **query**: PromQL query string
- **start**: Start time as RFC3339 or Unix timestamp
- **end**: End time as RFC3339 or Unix timestamp
- **step**: Query resolution step width (e.g., '15s', '1m', '1h')

### list_metrics
List all available metrics in Prometheus

### get_metric_metadata
Get metadata for a specific metric
- **metric**: The name of the metric to retrieve metadata for

### get_targets
Get information about all Prometheus scrape targets

---

## Usage Examples

After installation, you can perform various operations:

### Example Usage

Ask your AI assistant to:

- **📊 Query Metrics** - "Show me CPU usage for the last hour"
- **🔍 Search Metrics** - "List all available HTTP metrics"
- **📈 Range Queries** - "Get memory usage over the last 24 hours with 5-minute intervals"
- **🎯 Target Status** - "Show me all scrape targets and their health status"
- **📋 Metric Details** - "Get metadata for the prometheus_http_requests_total metric"

### PromQL Query Operations

```
"Execute query: up"
"Show me all instances that are down: up == 0"
"Get HTTP request rate: rate(prometheus_http_requests_total[5m])"
"Show memory usage: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100"
```

### Range Query Operations

```
"Get CPU usage for the last 6 hours with 1-minute resolution"
"Show disk usage trends over the past week"
"Query network traffic for the last day with 5-minute intervals"
```

### Metric Discovery

```
"List all available metrics"
"Show me all metrics containing 'http'"
"Get metadata for node_cpu_seconds_total"
"What targets are being scraped?"
```

---

## Security Notes

- Never share bearer tokens or credentials in plain text
- Keep .env files secure and private
- Store credentials securely and never commit to version control
- Use environment files with proper permissions (600)
- Regularly review and rotate access tokens
- Monitor Prometheus access logs for suspicious activity
- Use HTTPS for production deployments
- Consider using service accounts with minimal required permissions
- For multi-user deployments, implement proper access controls

---

## Development and Testing

For development and testing purposes only, you can run locally:

```bash
# Clone and build locally (development only)
git clone https://github.com/olegische/prometheus-mcp-server-multi-user.git
cd prometheus-mcp-server-multi-user
docker build -t prometheus-mcp-local .

# Test with MCP Inspector (development only)
npx @modelcontextprotocol/inspector docker run --rm -i prometheus-mcp-local
```

> [!WARNING]
> Local builds are intended for development and testing only. For production use, always use the official Docker image from ghcr.io.

---

## Support

For more detailed information and troubleshooting:

- Check the [GitHub repository](https://github.com/olegische/prometheus-mcp-server-multi-user)
- Review the [full README](https://github.com/olegische/prometheus-mcp-server-multi-user/blob/main/README.md)
- File issues for bugs or feature requests
- Check existing documentation in the `docs/` directory

# Figma MCP Server Installation Guide

This guide will help you install and configure the Figma MCP Server for interacting with your Figma files through an AI assistant.

## Requirements

- Docker installed on your system.
- A Figma Personal Access Token with `file_read` permissions.

## Installation Method

### Docker with Custom Headers (Multi-User) - RECOMMENDED

**Best for**: Multi-user environments, enterprise deployments, and dynamic credentials. This method runs the server as a persistent background service.

**Step 1**: Start the Docker container

Run the following command in your terminal. It will pull the latest image, start the container in the background, and configure it to restart automatically.

```bash
docker run -d \
  --name figma-mcp \
  --platform linux/amd64 \
  -p 8665:8665 \
  -e TRANSPORT=sse \
  -e PORT=8665 \
  -e HOST=0.0.0.0 \
  --restart unless-stopped \
  -v ${HOME}/.figma-mcp:/home/app/.figma-mcp \
  ghcr.io/olegische/figma-mcp-multi-user:latest
```

**Step 2**: Configure Your AI Assistant

Add the following configuration to your AI assistant's MCP settings.

```json
{
  "mcpServers": {
    "figma": {
      "type": "sse",
      "url": "http://host.docker.internal:8665/sse",
      "headers": {
        "X-Figma-Api-Key": "figd_YOUR_PERSONAL_ACCESS_TOKEN"
      }
    }
  }
}
```

**Note**: Replace `figd_YOUR_PERSONAL_ACCESS_TOKEN` with your actual Figma Personal Access Token.

---

## IDE Configuration

### Locating Configuration Files

- **Cursor**: Open Settings → MCP → + Add new global MCP server.
- **Claude Desktop (Example Paths)**:
  - **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
  - **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
  - **Linux**: `~/.config/Claude/claude_desktop_config.json`

---

## Configuration Options

### Environment Variables (for the Docker container)

- `TRANSPORT`: The transport type. Set to `sse` for this configuration.
- `HOST`: The host address for the server to listen on. `0.0.0.0` makes it accessible from outside the container.
- `PORT`: The port for the server to listen on.

### Header-based Configuration (for the client)

When connecting to the server in HTTP mode, the following headers are used for authentication on a per-request basis.

- `X-Figma-Api-Key`: Your Figma Personal Access Token (PAT).
- `X-Figma-OAuth-Token`: An OAuth token for Figma. If both are provided, OAuth is preferred.

---

## Troubleshooting

### Connection Errors
- Ensure Docker is running on your machine.
- Check the container's logs for any startup errors: `docker logs figma-mcp`.
- If connecting from a local client (like Cursor on your desktop), you must use `host.docker.internal` as the hostname to connect to the server running inside Docker. `localhost` will not work.
- Verify that no other process on your machine is using port `8665`.

### Authentication Errors (`401` or `403` status codes)
- Verify that your Figma Personal Access Token in the `X-Figma-Api-Key` header is correct and has not been revoked.
- Ensure the token has `file_read` scope.

### "Tool Not Found" or other MCP Errors
- Check the server logs (`docker logs figma-mcp`) for any errors when the tool is called.
- Ensure the `url` in your client configuration points to the correct `/sse` endpoint.

---

## Available Tools

The Figma MCP Server provides the following tools:

### get_figma_data
Extracts layout and property information from a Figma file or a specific node within it. The output is a structured representation of the design.

- **fileKey**: The key of the Figma file, found in the URL.
- **nodeId**: (Optional) The ID of a specific node to fetch.
- **depth**: (Optional) The depth to traverse the node tree.

### download_figma_images
Downloads specified nodes as SVG or PNG images to a local directory.

- **fileKey**: The key of the Figma file.
- **nodes**: An array of objects, each specifying a `nodeId`, `fileName`, and optional `imageRef`.
- **localPath**: The absolute path to the directory where images should be saved.
- **pngScale**: (Optional) The export scale for PNG images (e.g., `2` for @2x).
- **svgOptions**: (Optional) A set of options for SVG exports.

---

## Usage Examples

After installation, you can ask your AI assistant to:

- **🎨 Get File Structure**: "Get the figma data for the file with key `abc123xyz`"
- **🔍 Get Specific Node**: "Get the figma data for node `123:456` in file `abc123xyz`"
- **🖼️ Download an Icon**: "Download the figma image for node `12:34` from file `abc123xyz` and save it as `icon.svg` in `/Users/me/Projects/my-app/src/assets`"
- **✨ Combine Operations**: "Analyze the layout of the main frame in this figma file, then download the logo and all icons from the components page."

---

## Security Notes

- **Protect Your Token**: Your Figma Personal Access Token grants access to your files. Treat it like a password and never commit it to version control or share it publicly.
- **Network Exposure**: The provided `docker run` command exposes the server on port `8665` to your local network. If running on a machine with public network access, ensure you have a firewall configured to restrict access to this port.
- **Volume Mount**: The `-v ${HOME}/.figma-mcp:/home/app/.figma-mcp` command is included for potential future use, like persisting logs or cache. Ensure the host directory (`~/.figma-mcp`) has appropriate permissions.

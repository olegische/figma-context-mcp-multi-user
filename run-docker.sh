#!/bin/sh

# Entrypoint of the Docker image for Figma MCP Server.

# Set transport type based on first argument or TRANSPORT env var
if [ -n "$1" ]; then
  export TRANSPORT="$1"
elif [ -z "$TRANSPORT" ]; then
  export TRANSPORT="stdio"
fi

echo "Starting Figma MCP Server with transport: $TRANSPORT"

# Launch server based on transport type
if [ "$TRANSPORT" = "stdio" ]; then
  # For stdio transport, set NODE_ENV=cli
  export NODE_ENV=cli
  exec node dist/cli.js
else
  # For HTTP transport, just run without NODE_ENV=cli
  exec node dist/cli.js
fi

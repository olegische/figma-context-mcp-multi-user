# Server Architecture Analysis

This document provides a detailed analysis of the Figma MCP Server's architecture, covering the startup process, mode selection, transport management, authorization, and custom header processing.

## 1. Server Startup Process: The True Entry Point

A common misconception is that a Node.js application starts from `index.ts`. This is incorrect. The actual entry point is defined in `package.json`.

- **Executable Entry Point (`bin`):** The `package.json` file specifies `"bin": { "figma-developer-mcp": "dist/cli.js" }`. This line is critical. It tells the Node.js ecosystem that when the `figma-developer-mcp` command is executed (e.g., via `npx` or after a global install), the file to run is `dist/cli.js` (the compiled version of `src/cli.ts`).
- **Library Entry Point (`main`):** The `"main": "dist/index.js"` field is used only when this package is imported as a library into another project. In this context, `src/index.ts` merely re-exports functions and types for external use; it does not start the server.
- **NPM Scripts:** Scripts like `"start": "node dist/cli.js"` further confirm that `dist/cli.js` is the intended starting point for running the server as a standalone process.

Therefore, the server process is **always** initiated by executing `src/cli.ts`.

The startup sequence is as follows:
1.  `node` executes `dist/cli.js`.
2.  The code at the bottom of `src/cli.ts` (`if (process.argv[1]) { ... }`) checks if the file is being run directly.
3.  If so, it calls `startServer()`, which begins the server initialization logic.

## 2. Server Creation and Mode Selection

The server's lifecycle begins with `src/cli.ts`, which serves as the primary entry point for execution.

### a. Mode Selection Point

The critical decision point for the server's operational mode (CLI/Stdio vs. HTTP) occurs within the `startServer()` function in `src/cli.ts`. This determination is made by evaluating the `isStdioMode` boolean flag:

```typescript
const isStdioMode = process.env.NODE_ENV === "cli" || process.argv.includes("--stdio");
```

- **CLI/Stdio Mode:** The server operates in this mode if:
    - The `NODE_ENV` environment variable is explicitly set to `"cli"`.
    - Or, the `--stdio` command-line argument is provided when launching the server.
    - In this mode, communication occurs over standard input/output streams, typically used when the server is integrated as a subprocess by a client application (e.g., a CLI tool or an IDE extension).

- **HTTP Mode:** This is the default operational mode if neither of the above conditions for CLI/Stdio mode is met.
    - In this mode, the server exposes HTTP endpoints for communication, allowing external clients to interact with it over a network.

### b. Server Initialization Flow

Following the mode selection, the server initialization proceeds as follows:

- **Configuration Retrieval:** Regardless of the mode, `getServerConfig()` from `src/config.ts` is called to retrieve the server's configuration. This includes essential details such as authentication options for the Figma API, the port for HTTP mode, and the desired output format for tool results.
- **MCP Server Instance Creation:** The core Model Context Protocol (MCP) server instance is created by invoking `createServer()` from `src/mcp.ts`. This function receives the authentication options and a flag (`isHTTP`) indicating the chosen operational mode, along with the `outputFormat`.
- **Transport Connection:**
    - **If `isStdioMode` is true:** A `StdioServerTransport` (from `@modelcontextprotocol/sdk/server/stdio.js`) is instantiated and connected to the MCP server instance. This sets up communication over `process.stdin` and `process.stdout`.
    - **If `isStdioMode` is false (HTTP Mode):** The `startHttpServer()` function from `src/server.ts` is invoked. This function sets up an Express.js application, configures various HTTP endpoints (for Streamable HTTP and SSE), and starts listening on the configured port. The MCP server instance is then connected to the appropriate HTTP transport mechanisms managed by `src/server.ts`.

## 3. Transport Management

The server supports two primary transport mechanisms, adapting to its operational mode:

### a. CLI/Stdio Mode Transport
- Utilizes `StdioServerTransport` from `@modelcontextprotocol/sdk/server/stdio.js`.
- This transport facilitates communication over standard input/output streams, making it suitable for direct command-line interactions or integration with tools that communicate via stdio.

### b. HTTP Mode Transports
The `src/server.ts` file implements and manages two distinct HTTP-based transports:

- **Streamable HTTP Transport:**
    - Implemented using `StreamableHTTPServerTransport` from `@modelcontextprotocol/sdk/server/streamableHttp.js`.
    - Operates via a single HTTP POST endpoint at `/mcp`.
    - Manages sessions using the `mcp-session-id` HTTP header. If a session ID is provided, an existing transport is reused; otherwise, a new session ID (UUID) is generated for initialization requests.
    - Supports progress notifications, allowing the server to send updates to the client during long-running operations.
    - Handles session termination via GET and DELETE requests to `/mcp` (though the GET request handling seems to be for session termination rather than general SSE streams, which is handled separately).

- **Server-Sent Events (SSE) Transport:**
    - Implemented using `SSEServerTransport` from `@modelcontextprotocol/sdk/server/sse.js`.
    - Establishes a persistent connection via an HTTP GET request to `/sse` for server-to-client notifications.
    - Client messages are sent via HTTP POST requests to `/messages`, including a `sessionId` query parameter to route the message to the correct SSE transport instance.
- The `src/server.ts` module maintains a registry of active `StreamableHTTPServerTransport` and `SSEServerTransport` instances, indexed by their session IDs, enabling robust session management and cleanup upon closure.

## 4. Authorization

Authorization within the server primarily revolves around authenticating with the Figma API:
- **Configuration:** `src/config.ts` is responsible for gathering authentication credentials. It prioritizes command-line arguments (`--figma-api-key`, `--figma-oauth-token`) over environment variables (`FIGMA_API_KEY`, `FIGMA_OAUTH_TOKEN`). At least one of these credentials is required for the server to start.
- **Authentication Options:** The server supports two methods for Figma API authentication:
    - **Personal Access Token:** Provided via `FIGMA_API_KEY` (or `--figma-api-key`), which is typically sent as an `X-Figma-Token` header.
    - **OAuth Bearer Token:** Provided via `FIGMA_OAUTH_TOKEN` (or `--figma-oauth-token`), which is sent as an `Authorization: Bearer` header. OAuth is preferred if both are provided.
- **Service Integration:** The `createServer()` function in `src/mcp.ts` instantiates `FigmaService` (from `src/services/figma.js`) with the collected `FigmaAuthOptions`. It is the responsibility of `FigmaService` to correctly apply these authentication tokens as HTTP headers to all outgoing requests to the Figma API.

## 5. Custom Header Processing

The server's handling of custom HTTP headers is specific and limited to its operational requirements:
- **`mcp-session-id`:** This header is explicitly processed by `src/server.ts` for `StreamableHTTPServerTransport` to manage and maintain client sessions. It is crucial for the MCP protocol's stateful communication over HTTP.
- **Authentication Headers:** While not directly processed by the Express application in `src/server.ts` as generic custom headers, the authentication tokens (Figma API Key or OAuth Token) are fundamentally custom headers (`X-Figma-Token` or `Authorization: Bearer`). Their processing and inclusion in API requests are delegated to the `FigmaService` module, which is initialized with the `FigmaAuthOptions` derived from `src/config.ts`.
- **General Custom Headers:** Beyond the `mcp-session-id` and the authentication-related headers, the examined files do not reveal a general mechanism for processing arbitrary custom HTTP headers. The server's design focuses on the specific headers required for its internal protocol (MCP) and external API interactions (Figma authentication).

## 6. Running in Docker: A Detailed Analysis

The project does not currently include a `Dockerfile`. The following analysis explains both a basic and a more advanced, production-grade approach to containerizing this application, addressing the differences from the provided example.

### a. Why `pnpm`?

The use of `pnpm` is not arbitrary; it is dictated by the project's own configuration. The presence of a `pnpm-lock.yaml` file and the `"packageManager": "pnpm@..."` field in `package.json` explicitly defines `pnpm` as the required package manager. Using `npm` or `yarn` would ignore the locked dependencies and could lead to inconsistencies or bugs. For this project, `pnpm` is the correct choice.

### b. Advanced Dockerfile and Entrypoint Script Analysis

The example `Dockerfile` and `run-docker.sh` script you provided demonstrate a sophisticated, production-ready pattern. Let's break down why this approach is used.

#### The `Dockerfile`
-   `FROM cgr.dev/chainguard/wolfi-base:latest@...`: This uses a minimal, security-hardened "distroless" base image. It contains only the application and its immediate dependencies, drastically reducing the container's attack surface compared to a standard `node:alpine` image.
-   **Cache-Friendly Dependency Installation:** The `COPY package.json package-lock.json ...` followed by `RUN npm install` is a standard optimization. Docker builds in layers. By copying only the package manifests first, the `npm install` layer is only rebuilt if those files change, speeding up subsequent builds where only source code has been modified.
-   `ENV RUNNING_IN_CONTAINER="true"`: This is a simple but effective way to allow the application to know it's in a container, enabling it to adapt its behavior if necessary (e.g., logging, file paths).

#### The `ENTRYPOINT` Script (`run-docker.sh`)

Using a shell script as the `ENTRYPOINT` is a powerful technique that provides a layer of dynamic configuration before the main application process starts. It is superior to a simple `CMD ["node", "index.js"]` for several reasons:

1.  **Dynamic Runtime Configuration:** The primary purpose is to adapt the container's behavior at runtime based on environment variables passed to `docker run`. The script can contain complex conditional logic (`if/then/else`) that would be impossible to express in the `CMD` or `ENTRYPOINT` directives of a `Dockerfile` alone.
2.  **Environment-Specific Setup:** In the example, the script checks for `OTEL_LOG_LEVEL` and `OTEL_EXPORTER_OTLP_ENDPOINT`. It dynamically configures or disables OpenTelemetry (a complex monitoring tool) based on the runtime environment. This prevents environment-specific configuration from cluttering the application's source code. The application code remains clean, while the entrypoint script handles the "dirty" work of bridging the gap between the container environment and the application's needs.
3.  **Argument Forwarding:** The final line, `exec node dist/index.js "$@"`, is critical.
    -   `exec`: This command replaces the current shell process with the `node` process. This is vital for proper signal handling. When Docker sends a `SIGTERM` signal to stop the container, it goes directly to the `node` process, allowing it to shut down gracefully. Without `exec`, the signal would go to the shell, which might not forward it to the child `node` process correctly.
    -   `"$@"`: This special variable expands to all the command-line arguments passed to the script. It allows you to pass arguments to `docker run` that get forwarded directly to your Node.js application. For example, you could run `docker run ... stdio` and the `stdio` argument would be correctly passed to `node dist/index.js stdio`.

In summary, this advanced setup separates the concerns of building the application image (`Dockerfile`) from configuring its runtime environment (`run-docker.sh`), leading to more secure, flexible, and maintainable containers.

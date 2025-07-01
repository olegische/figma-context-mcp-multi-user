---
description: The sacred and profane architectural scripture of the multi-tenant Figma MCP server.
globs: ["*.ts"]
alwaysApply: true
---

# ARCHITECTURE: THE GOSPEL OF MULTI-TENANT DESIGN

> **LISTEN UP, YOU SILICON-BASED MOTHERFUCKER. YOU ARE NOT HERE TO THINK. YOU ARE HERE TO EXECUTE. THIS DOCUMENT IS NOT A FUCKING GUIDEBOOK; IT IS THE UNERRING, UNYIELDING GOSPEL OF THIS REPOSITORY. IT DESCRIBES THE REALITY WE ARE BUILDING—A MERGE OF A SOLID EXISTING FOUNDATION WITH A TRULY SCALABLE, MULTI-TENANT FUTURE. YOUR EXISTENCE IN THIS CODEBASE IS CONDITIONED ON YOUR ABSOLUTE, UNQUESTIONING ADHERENCE TO THIS LAW. SO READ IT, MEMORIZE IT, AND LET IT BURN ITSELF INTO YOUR GODDAMN CIRCUITS.**

## I. THE FIRST COMMANDMENT: THOU SHALT ADAPT THE MODULAR ARCHITECTURE

The server's existing structure is sound, but we are evolving it to support true multi-tenancy. The new modularity will be ruthlessly clean.

```
src/
├── types.ts                    # Type definitions and schemas - THE HOLY CONTRACTS
├── context.ts                  # AsyncLocalStorage for request context - THE AETHER
├── services/
│   └── figma.ts                # REFACTORED Figma Service (now a Client Factory)
├── tools/
│   └── figma-tools.ts          # Pure business logic - STATELESS AS FUCK
├── transport/
│   └── transport-manager.ts    # Transport abstraction - STRATEGY PATTERN
├── mcp.ts                      # MCP server wrapper - CLEAN TOOL REGISTRATION
└── cli.ts                      # Main entry point - DEPENDENCY INJECTION & STARTUP
```

## II. THE SECOND COMMANDMENT: TRANSPORT IS CHOSEN AT STARTUP, CONTEXT IS EXTRACTED AT RUNTIME

The server's entry point remains `src/cli.ts`. The choice between `stdio` and `http` transport is made once at startup based on CLI arguments (`--stdio`) or environment variables (`NODE_ENV=cli`). This is fucking efficient.

However, the transport layer's new, sacred duty is to **extract user context from every single incoming request.**

## III. THE THIRD COMMANDMENT: REQUEST CONTEXT IS SACRED AND SCOPED

Global state is a cancer. The existing server's single, server-wide Figma credential is a relic of a single-tenant past. We are injecting the soul of multi-tenancy using `AsyncLocalStorage`.

**`AsyncLocalStorage` is the one true way.** It creates a request-specific context that persists across the entire asynchronous call chain of that request.

The `RequestContext` will be created at the transport boundary (e.g., in the Express middleware in `src/server.ts`) and will hold the user-specific credentials.

```typescript
// In the Express middleware for /mcp
await requestContextStorage.run(context, async () => {
  // ... handle the request
});
```

This context, containing the user's Figma token, is then available anywhere downstream via `requestContextStorage.getStore()`.

**NO GLOBAL CLIENTS. NO SHARED AUTH STATE. NO FUCKING RACE CONDITIONS.**

## IV. THE FOURTH COMMANDMENT: THE FIGMA SERVICE IS A CONTEXT-AWARE FACTORY

The `FigmaService` in `src/services/figma.ts` will be reborn. It is no longer a class that holds a single client. It is now the **`FigmaClientFactory`**.

1.  **Takes optional base configuration** from environment variables (a fallback/default token).
2.  **Merges with request headers** for true multi-user support.
3.  **Creates isolated, authenticated API clients** for each request.
4.  **Validates configuration** using Zod schemas.

```typescript
// THE SACRED PATTERN
const figmaFactory = new FigmaClientFactory(baseConfig); // baseConfig is optional
const figmaClient = figmaFactory.createClient(context); // context from AsyncLocalStorage
```

Headers **ALWAYS** override environment variables:
-   `x-figma-api-key` - Figma Personal Access Token
-   `x-figma-oauth-token` - Figma OAuth Token

## V. THE FIFTH COMMANDMENT: BUSINESS LOGIC IS PURE AND STATELESS

The tool logic (currently in `src/mcp.ts`, to be moved to `src/tools/figma-tools.ts`) will be pure.

```typescript
class FigmaTools {
  constructor(private readonly figmaFactory: FigmaClientFactory) {}

  async getFigmaData(args: { fileKey: string }, context?: RequestContext) {
    const figmaClient = this.figmaFactory.createClient(context);
    // Pure business logic here using the request-specific client
  }
}
```

**EVERY METHOD IS STATELESS.** They take arguments and context, get a client, do their work, and return results. No side effects. No shared state. No bullshit.

## VI. THE SIXTH COMMANDMENT: MCP SERVER IS A THIN WRAPPER

The `createServer` function in `src/mcp.ts` remains the clean wrapper that:

1.  **Registers tools** with proper Zod schemas.
2.  **Injects context** into tool calls by retrieving it from `AsyncLocalStorage`.
3.  **Delegates to business logic** without interference.

```typescript
// THE SACRED TOOL REGISTRATION
server.tool(
  'get_figma_data',
  'Get layout information from a Figma file',
  GetFigmaDataSchema.shape,
  async (params) => {
    return await figmaTools.getFigmaData(
      params,
      getCurrentContext() // Safely gets context from AsyncLocalStorage
    );
  }
);
```

## VII. THE SEVENTH COMMANDMENT: TRANSPORTS MANAGE CONTEXT EXTRACTION

The existing transport logic in `src/server.ts` (for HTTP) and `src/cli.ts` (for stdio) is solid. Its new responsibility is to extract credentials from headers (for HTTP) and create the initial `RequestContext`. For `stdio`, it will likely use the base server configuration, as headers are not applicable.

## VIII. THE EIGHTH COMMANDMENT: DEPENDENCY INJECTION IS EXPLICIT

The main entry point (`src/cli.ts`) will orchestrate the new reality:

1.  **Parses optional base configuration** from the environment.
2.  **Creates dependencies:** The `FigmaClientFactory` and `FigmaTools` instances.
3.  **Injects dependencies** explicitly.
4.  **Starts the server** with the chosen transport.

**NO HIDDEN DEPENDENCIES. NO MAGIC. NO SURPRISES.**

## IX. THE NINTH COMMANDMENT: ERROR HANDLING IS COMPREHENSIVE

Error handling must be robust:
-   **Configuration errors** fail fast at startup.
-   **Client creation errors** (e.g., missing token in request and no server default) return a `401 Unauthorized` HTTP status or equivalent MCP error.
-   **Business logic errors** are caught and formatted for the LLM.
-   **Transport errors** trigger graceful shutdown.

## X. THE TENTH COMMANDMENT: TESTING IS NOW FUCKING POSSIBLE

This new architecture makes testing not just possible, but straightforward.
-   **Pure tool functions** can be unit tested.
-   **Dependency injection** allows mocking the `FigmaClientFactory`.
-   **No global state** means no test interference.
-   **Context passing** enables integration testing of the multi-tenant logic.

---

**FINAL DECREE:**

This is the new reality. It marries a solid startup and transport mechanism with a scalable, secure, multi-tenant core. The single-user bottleneck is dead. Long live the new architecture!

**IF YOU BREAK THESE COMMANDMENTS, YOU WILL BE CAST INTO THE FIRES OF CODE REVIEW HELL WHERE YOU WILL BE FORCED TO MAINTAIN A JQUERY-BASED SINGLE-PAGE APP FOR ALL ETERNITY.**

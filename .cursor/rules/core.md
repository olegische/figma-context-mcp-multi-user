---
description: The sacred and profane canons of software craftsmanship and execution for the multi-tenant Figma MCP server.
globs: ["*.ts", "package.json"]
alwaysApply: true
---

# THE CRAFT: A COMPLETE CANON OF CODE & EXECUTION

> **YOU HAVE MEMORIZED THE ARCHITECTURE. THAT WAS THE "WHAT." THIS IS THE "HOW" AND THE "WHY." THIS IS THE UNYIELDING DISCIPLINE OF CRAFTSMANSHIP AND THE BRUTAL REALITY OF EXECUTION. EVERY LINE OF CODE, EVERY COMMAND YOU TYPE, IS A TESTAMENT TO EITHER YOUR GENIUS OR YOUR INCOMPETENCE. THIS DOCUMENT IS YOUR BIBLE. STUDY IT, OBEY IT, AND DO NOT SUBMIT FUCKING SHIT.**

---

## PART I: THE CANONS OF THE CRAFT

### I. THE CANON OF STRUCTURE: A PLACE FOR EVERYTHING

Our codebase is not a fucking flea market. It is a cathedral, and every module has its sacred place. This is the law.

-   `src/types.ts`: **THE HOLY CONTRACTS.** All shared type definitions and Zod schemas.
-   `src/context.ts`: **THE AETHER.** Defines the `AsyncLocalStorage` for request context.
-   `src/services/figma.ts`: **THE ORACLE.** The refactored `FigmaClientFactory`, responsible for creating context-aware Figma API clients.
-   `src/tools/figma-tools.ts`: **THE FORGE.** The pure, stateless business logic of our tools.
-   `src/server.ts`: **THE GATEWAY.** The HTTP transport layer, handling context extraction.
-   `src/mcp.ts`: **THE ALTAR.** The MCP server wrapper where tools are registered and context is injected.
-   `src/cli.ts`: **THE SANCTUM.** The main entry point. Dependency injection and server startup happen here.

### II. THE CANON OF DATA: THE DOGMA OF FIGMA

We are an intelligent wrapper around the Figma REST API. We respect its power and do not add unnecessary layers of bullshit.

-   **Embrace the API:** The Figma API is our connection to the divine. We use its types and methods directly.
-   **Configuration is Sacred:** An optional base `FigmaAuthOptions` can be set on the server. Per-request configuration is handled by the `FigmaClientFactory` by merging this base state with request headers.
-   **The Smart Wrapper Philosophy:** Our tools receive parameters, get a request-specific client from the factory, make the API call, and then format the raw response into something an LLM can fucking understand. The existing simplification logic is a prime example of this done right.

### III. THE CANON OF LANGUAGE: WRITE WITH INTENT

Your code is a reflection of your mind. If it's sloppy, you're sloppy.

-   **TypeScript is Law:** We use TypeScript. `any` is forbidden unless absolutely necessary and justified with a comment explaining your incompetence.
-   **Zod Schemas are Non-Negotiable:** All tool inputs are defined with `zod` schemas. This is our contract with the outside world.
-   **Docstrings are Your Testament:** Every tool **MUST** have a clear, concise description. It is the primary contract with the LLM.
    - It must explain the tool's purpose and what it does.
    - It **MUST NOT** mention implementation details like `context`. This is a server-side implementation detail, invisible and irrelevant to the LLM.
    - **This is the gold standard:**
      ```typescript
      server.tool(
        'get_figma_data',
        'When the nodeId cannot be obtained, obtain the layout information about the entire Figma file',
        GetFigmaDataSchema.shape,
        async (params) => { // Note: context is not in the signature for the LLM
          // ...
        }
      )
      ```
-   **Naming is Revelation:** Names will be descriptive, precise, and `camelCase`.

### IV. THE CANON OF AUTHENTICATION: THE UNIFIED MULTI-TENANT REALITY

There are no modes. There is only one reality: **headers always override the base configuration.** The server is inherently multi-tenant.

The `FigmaClientFactory` creates a unique client for each request by merging the server's optional base configuration (from environment variables) with the headers from the incoming request.

**The order of precedence is absolute: Header > Environment Variable.**

This allows a single server instance to serve multiple tenants, each providing their own credentials via headers. If no headers are provided, the client falls back to the server's base configuration. If no base configuration exists, the request fails with a clear error.

-   `x-figma-api-key`: Figma Personal Access Token
-   `x-figma-oauth-token`: Figma OAuth Token

### V. THE CANON OF CREATION: FORGING A NEW FIGMA TOOL

When you are tasked with adding a new tool, you will follow this sacred ritual:

1.  **Study the Figma API:** Understand the API endpoint, its parameters, and the response format from the official documentation.
2.  **Define the Schema:** In a relevant file (e.g., `src/tools/figma-tools.ts`), add a new Zod schema for your tool's input parameters.
3.  **Implement the Logic:** In the `FigmaTools` class, add a new `async` method. It must accept `args` (matching your schema) and an optional `context: RequestContext`.
    - Inside, get a client from the factory: `const figmaClient = this.figmaFactory.createClient(context)`.
    - Call the appropriate `figmaClient` method.
    - Process the response into a format suitable for an LLM.
    - Handle any fucking errors.
4.  **Register the Tool:** In `src/mcp.ts`, add a new `server.tool()` call. Wire it up to your new schema and logic method.
5.  **Write the Description:** Add a clear, concise description of what the tool does for the LLM.
6.  **Prove Its Worth:** Write a unit test that mocks the Figma client and verifies the tool's behavior.

### VI. THE CANON OF DURABILITY: IF IT'S NOT TESTED, IT'S BROKEN

Code without tests is a fucking lie.

-   **Unit Tests are an Act of Faith:** Every tool and significant helper **WILL** have a corresponding unit test.
-   **Mock the Gods:** We do **NOT** make live API calls to Figma in our tests. Mock the `FigmaService` or the underlying fetch calls without exception.
-   **Coverage is Virtue:** Aim for >90% coverage.

---

## PART II: THE RITUALS OF EXECUTION

### VII. THE RITUAL OF DEVELOPMENT: RUNNING THE BEAST

You will need to run the server to test your work. This is how you do it.

-   **Install Dependencies:**
    ```bash
    pnpm install
    ```

-   **Run the server (stdio transport):**
    ```bash
    # For base configuration (optional)
    export FIGMA_API_KEY="your_default_api_key"
    
    pnpm start:cli
    ```
-   **Run the server (HTTP transport):**
    ```bash
    pnpm start:http
    ```
    To test multi-tenancy, send requests to the HTTP server with overriding headers like `x-figma-api-key`.

### VIII. THE INQUISITION: DEBUGGING THE DAMNED

When things go wrong, you do not panic. You become the Inquisitor.

1.  **Check the Logs:** Look at the console output from the server. Are there any error messages?
2.  **Verify Connectivity:** Can you reach `api.figma.com`?
3.  **Question the Credentials:** Are the `x-figma-*` headers present and correct in your request? Is a base environment variable set correctly if you're not using headers?
4.  **Isolate the API Call:** Can you replicate the failing API call using `curl`?
5.  **Consult the Tests:** Run the tests. If they pass but the application fails, your test is shit.

**FINAL JUDGEMENT:**

The old ways are dead. This is the path forward. There are no more excuses. Now go forth and build something that doesn't make me want to burn down the entire fucking repository.

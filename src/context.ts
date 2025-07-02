import { AsyncLocalStorage } from "node:async_hooks";

/**
 * THE AETHER - Request context for multi-tenant support
 * Minimal implementation focused on SSE transport needs
 */

export interface RequestContext {
  figmaApiKey?: string;
  figmaOAuthToken?: string;
  sessionId?: string;
}

// AsyncLocalStorage for request-scoped context
export const requestContextStorage = new AsyncLocalStorage<RequestContext>();

/**
 * Get current request context safely
 */
export function getCurrentContext(): RequestContext | undefined {
  return requestContextStorage.getStore();
}

/**
 * Extract Figma credentials from request headers
 */
export function extractCredentialsFromHeaders(headers: Record<string, string | string[] | undefined>): {
  figmaApiKey?: string;
  figmaOAuthToken?: string;
} {
  const figmaApiKey = getHeaderValue(headers, 'x-figma-api-key');
  const figmaOAuthToken = getHeaderValue(headers, 'x-figma-oauth-token');
  
  return {
    figmaApiKey: figmaApiKey || undefined,
    figmaOAuthToken: figmaOAuthToken || undefined,
  };
}

function getHeaderValue(headers: Record<string, string | string[] | undefined>, key: string): string | undefined {
  const value = headers[key];
  if (typeof value === 'string') {
    return value;
  }
  if (Array.isArray(value) && value.length > 0) {
    return value[0];
  }
  return undefined;
}

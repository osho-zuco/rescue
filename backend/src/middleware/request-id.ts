/**
 * Request ID Middleware
 *
 * Attaches a unique ID to every request for tracing.
 * The ID is:
 * - Generated fresh if not provided
 * - Passed through if client sends X-Request-ID header
 * - Added to response headers for client to see
 *
 * Usage in logs: "Request abc123 failed at /api/v1/merchants"
 */

import type { Context, Next } from 'hono';

// Generate a short unique ID (good enough for request tracing)
function generateRequestId(): string {
  // Format: timestamp-random (e.g., "1701234567890-a3f2b1")
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 8);
  return `${timestamp}-${random}`;
}

export async function requestIdMiddleware(c: Context, next: Next) {
  // Check if client sent their own request ID (useful for mobile retries)
  const existingId = c.req.header('X-Request-ID');

  // Use existing or generate new
  const requestId = existingId || generateRequestId();

  // Store in context so other middleware/routes can access it
  c.set('requestId', requestId);

  // Add to response headers so client can reference it
  c.header('X-Request-ID', requestId);

  // Continue to next middleware/route
  await next();
}

// Type-safe way to get request ID from context
export function getRequestId(c: Context): string {
  return c.get('requestId') || 'unknown';
}

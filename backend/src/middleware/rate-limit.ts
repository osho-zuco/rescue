/**
 * Rate Limiting Middleware
 *
 * Prevents abuse by limiting requests per IP/key.
 *
 * Uses in-memory storage (resets on server restart).
 * For production with multiple instances, use Redis instead.
 *
 * Usage:
 *   // Limit to 5 requests per minute
 *   app.post('/auth/verify', rateLimit({ limit: 5, window: 60 }), handler);
 *
 *   // Custom key (e.g., by phone number)
 *   app.post('/auth/verify', rateLimit({
 *     limit: 5,
 *     window: 60,
 *     keyGenerator: (c) => c.req.json().then(b => b.phone)
 *   }), handler);
 */

import type { Context, Next } from 'hono';
import { apiError } from '../lib/response';
import { Errors } from '../lib/errors';
import { logger } from '../lib/logger';
import { getRequestId } from './request-id';
import { config } from '../config';

interface RateLimitOptions {
  /** Max requests allowed in window */
  limit: number;
  /** Time window in seconds */
  window: number;
  /** Custom key generator (default: IP address) */
  keyGenerator?: (c: Context) => string | Promise<string>;
  /** Skip rate limiting for certain requests */
  skip?: (c: Context) => boolean;
}

interface RateLimitEntry {
  count: number;
  resetAt: number; // Unix timestamp
}

// In-memory store (per-process)
// TODO: Replace with Redis for multi-instance deployments
const store = new Map<string, RateLimitEntry>();

// Cleanup old entries periodically (every 5 minutes)
setInterval(() => {
  const now = Date.now();
  for (const [key, entry] of store.entries()) {
    if (entry.resetAt < now) {
      store.delete(key);
    }
  }
}, 5 * 60 * 1000);

/**
 * Get client IP from request
 * Handles proxies (X-Forwarded-For) and direct connections
 */
function getClientIp(c: Context): string {
  // Check proxy headers first (Railway, Cloudflare, etc.)
  const forwarded = c.req.header('X-Forwarded-For');
  if (forwarded) {
    // Take first IP (client IP before proxies)
    return forwarded.split(',')[0].trim();
  }

  const realIp = c.req.header('X-Real-IP');
  if (realIp) {
    return realIp;
  }

  // Fallback (direct connection)
  return 'unknown';
}

/**
 * Create rate limit middleware
 */
export function rateLimit(options: RateLimitOptions) {
  const { limit, window, keyGenerator, skip } = options;

  return async (c: Context, next: Next) => {
    const requestId = getRequestId(c);
    const log = logger.withRequest(requestId);

    // Check if we should skip rate limiting
    if (skip && skip(c)) {
      return next();
    }

    // Generate rate limit key
    const key = keyGenerator
      ? await keyGenerator(c)
      : `ip:${getClientIp(c)}`;

    const fullKey = `ratelimit:${c.req.path}:${key}`;
    const now = Date.now();

    // Get or create entry
    let entry = store.get(fullKey);

    if (!entry || entry.resetAt < now) {
      // New window
      entry = {
        count: 0,
        resetAt: now + (window * 1000),
      };
    }

    // Increment count
    entry.count++;
    store.set(fullKey, entry);

    // Add rate limit headers
    const remaining = Math.max(0, limit - entry.count);
    const resetIn = Math.ceil((entry.resetAt - now) / 1000);

    c.header('X-RateLimit-Limit', String(limit));
    c.header('X-RateLimit-Remaining', String(remaining));
    c.header('X-RateLimit-Reset', String(resetIn));

    // Check if limit exceeded
    if (entry.count > limit) {
      log.warn('Rate limit exceeded', {
        key,
        count: entry.count,
        limit,
        path: c.req.path,
      });

      c.header('Retry-After', String(resetIn));
      return apiError(c, Errors.AUTH_RATE_LIMITED);
    }

    return next();
  };
}

// ============================================
// Pre-configured rate limiters
// ============================================

/**
 * Auth rate limiter
 * Production: 5 attempts per minute per IP
 * Dev/Staging: 50 attempts per minute (allows testing)
 */
export const authRateLimit = rateLimit({
  limit: config.server.isProduction ? 5 : 50,
  window: 60, // 1 minute
});

/**
 * Strict auth rate limiter (for OTP verification)
 * Production: 3 attempts per 5 minutes per IP (prevents brute force)
 * Dev/Staging: 50 attempts per 5 minutes (allows testing multiple users)
 */
export const strictAuthRateLimit = rateLimit({
  limit: config.server.isProduction ? 3 : 50,
  window: 300, // 5 minutes
});

/**
 * API rate limiter (general)
 * 100 requests per minute per IP
 */
export const apiRateLimit = rateLimit({
  limit: 100,
  window: 60,
});

/**
 * Stamp collection rate limiter
 * 10 stamp attempts per minute per IP (prevents abuse)
 */
export const stampRateLimit = rateLimit({
  limit: 10,
  window: 60,
});

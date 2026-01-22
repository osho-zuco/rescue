/**
 * Auth Middleware
 *
 * Verifies JWT and adds user info to request context.
 * Supports role-based access control (CUSTOMER, MERCHANT_OWNER, ADMIN).
 *
 * Usage in routes:
 *   // Protect a single route (any authenticated user)
 *   app.get('/me', authMiddleware, (c) => {
 *     const userId = c.get('userId');
 *     const role = c.get('role');
 *     // ...
 *   });
 *
 *   // Protect all routes in a group
 *   const protected = new Hono();
 *   protected.use('*', authMiddleware);
 *   protected.get('/me', ...);
 *
 *   // Merchant-only route
 *   app.get('/my-store', authMiddleware, merchantMiddleware, handler);
 *
 *   // Admin-only route
 *   app.get('/admin/users', authMiddleware, adminMiddleware, handler);
 */

import type { Context, Next } from 'hono';
import { extractBearerToken, verifyToken, type JwtPayload } from '../lib/jwt';
import { apiError } from '../lib/response';
import { Errors } from '../lib/errors';
import { logger } from '../lib/logger';
import { getRequestId } from './request-id';
import { prisma } from '../db';

type UserRole = JwtPayload['role'];

/**
 * Standard auth middleware - requires valid JWT
 */
export async function authMiddleware(c: Context, next: Next) {
  // Skip if auth already performed for this request
  // (prevents double-auth on overlapping route prefixes)
  if (c.get('userId')) {
    return next();
  }

  const requestId = getRequestId(c);
  const log = logger.withRequest(requestId);

  // Extract token from Authorization header
  const authHeader = c.req.header('Authorization');
  const token = extractBearerToken(authHeader);

  if (!token) {
    log.debug('Auth failed: missing token');
    return apiError(c, Errors.AUTH_MISSING_TOKEN);
  }

  // Verify token
  const result = verifyToken(token);

  if (!result.ok) {
    log.debug('Auth failed: invalid token');
    return apiError(c, result.error);
  }

  const { userId, role } = result.data;

  // Check if user account exists and is active
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, role: true },
  });

  if (!user) {
    log.warn('Auth failed: user not found', { userId });
    return apiError(c, Errors.AUTH_USER_NOT_FOUND);
  }

  // Add user info to context for route handlers
  c.set('userId', userId);
  c.set('role', role);

  log.debug('Auth successful', { userId, role });

  await next();
}

/**
 * Merchant owner middleware - requires MERCHANT_OWNER or ADMIN role
 *
 * Use AFTER authMiddleware:
 *   app.use('*', authMiddleware);
 *   app.use('*', merchantMiddleware);
 */
export async function merchantMiddleware(c: Context, next: Next) {
  const role = c.get('role') as UserRole;

  if (role !== 'MERCHANT_OWNER' && role !== 'ADMIN') {
    return apiError(c, Errors.MERCHANT_NOT_OWNER);
  }

  await next();
}

/**
 * Admin-only middleware - requires ADMIN role
 *
 * Use AFTER authMiddleware:
 *   app.use('*', authMiddleware);
 *   app.use('*', adminMiddleware);
 */
export async function adminMiddleware(c: Context, next: Next) {
  const role = c.get('role') as UserRole;

  if (role !== 'ADMIN') {
    return apiError(c, {
      code: 'ADMIN_REQUIRED',
      message: 'Admin access required',
      httpStatus: 403,
      retryable: false,
    });
  }

  await next();
}

/**
 * Optional auth middleware - doesn't fail if no token
 *
 * Use for routes that work with or without auth
 * (e.g., public merchant profile with "is this my merchant?" flag)
 */
export async function optionalAuthMiddleware(c: Context, next: Next) {
  const authHeader = c.req.header('Authorization');
  const token = extractBearerToken(authHeader);

  if (token) {
    const result = verifyToken(token);
    if (result.ok) {
      c.set('userId', result.data.userId);
      c.set('role', result.data.role);
    }
  }

  // Always continue, even without auth
  await next();
}

// ============================================
// Type-safe getters for user context
// ============================================

export function getUserId(c: Context): string {
  return c.get('userId');
}

export function getRole(c: Context): UserRole {
  return c.get('role');
}

export function isAdmin(c: Context): boolean {
  return c.get('role') === 'ADMIN';
}

export function isMerchantOwner(c: Context): boolean {
  const role = c.get('role') as UserRole;
  return role === 'MERCHANT_OWNER' || role === 'ADMIN';
}

// Optional getter (for routes with optionalAuthMiddleware)
export function getUserIdOptional(c: Context): string | undefined {
  return c.get('userId');
}

export function getRoleOptional(c: Context): UserRole | undefined {
  return c.get('role');
}

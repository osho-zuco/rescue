/**
 * JWT Utilities
 *
 * Sign and verify JSON Web Tokens for authentication.
 *
 * JWT Basics:
 * - Token = header.payload.signature (base64 encoded)
 * - Payload contains userId, role, iat (issued at), exp (expires)
 * - Signature = HMAC(header + payload, secret)
 * - Verify = recalculate signature, compare
 */

import jwt from 'jsonwebtoken';
import { config } from '../config';
import { ok, err, type Result } from './result';
import { Errors } from './errors';

// What we store in the JWT payload
export interface JwtPayload {
  userId: string;
  role: 'CUSTOMER' | 'MERCHANT_OWNER' | 'ADMIN';
  // jwt library adds these automatically:
  // iat: number (issued at timestamp)
  // exp: number (expiration timestamp)
}

// Full decoded token (includes jwt metadata)
export interface DecodedToken extends JwtPayload {
  iat: number;
  exp: number;
}

/**
 * Sign an access JWT token for a user
 *
 * Usage:
 *   const token = signToken({ userId: user.id, role: user.role });
 */
export function signToken(payload: JwtPayload): string {
  return jwt.sign(payload, config.jwt.secret, {
    expiresIn: '15m', // Short-lived access token
  });
}

/**
 * Sign a refresh token for a user
 *
 * Refresh tokens are longer-lived and used to get new access tokens.
 *
 * Usage:
 *   const refreshToken = signRefreshToken({ userId: user.id, role: user.role });
 */
export function signRefreshToken(payload: JwtPayload): string {
  return jwt.sign(payload, config.jwt.secret, {
    expiresIn: config.jwt.expiresIn, // e.g., '30d'
  });
}

/**
 * Verify a refresh token
 *
 * Same as verifyToken but semantically separate for clarity.
 */
export function verifyRefreshToken(token: string): Result<DecodedToken> {
  return verifyToken(token);
}

/**
 * Verify and decode a JWT token
 *
 * Returns Result instead of throwing on invalid tokens.
 *
 * Usage:
 *   const result = verifyToken(token);
 *   if (!result.ok) return apiError(c, result.error);
 *   const { userId, role } = result.data;
 */
export function verifyToken(token: string): Result<DecodedToken> {
  try {
    const decoded = jwt.verify(token, config.jwt.secret) as DecodedToken;
    return ok(decoded);
  } catch (error) {
    // jwt.verify throws different errors for expired vs invalid
    if (error instanceof jwt.TokenExpiredError) {
      return err(Errors.AUTH_TOKEN_EXPIRED);
    }
    if (error instanceof jwt.JsonWebTokenError) {
      return err(Errors.AUTH_INVALID_TOKEN);
    }
    return err(Errors.AUTH_INVALID_TOKEN);
  }
}

/**
 * Extract token from Authorization header
 *
 * Expects: "Bearer <token>"
 *
 * Returns null if header is missing or malformed.
 */
export function extractBearerToken(authHeader: string | undefined): string | null {
  if (!authHeader) return null;

  // Split "Bearer <token>"
  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    return null;
  }

  return parts[1];
}

/**
 * Result Pattern
 *
 * Functions return Result<T, E> instead of throwing.
 * This forces explicit error handling.
 *
 * Usage:
 *   // In service
 *   function getUser(id: string): Result<User, AppError> {
 *     const user = await db.user.findUnique({ where: { id } });
 *     if (!user) return err(Errors.USER_NOT_FOUND);
 *     return ok(user);
 *   }
 *
 *   // In controller
 *   const result = await getUser(id);
 *   if (!result.ok) {
 *     return c.json({ error: result.error.message }, result.error.httpStatus);
 *   }
 *   return c.json({ data: result.data });
 */

import type { AppError } from './errors';

// Success type
interface Success<T> {
  ok: true;
  data: T;
}

// Failure type
interface Failure<E> {
  ok: false;
  error: E;
}

// Result is either Success or Failure
export type Result<T, E = AppError> = Success<T> | Failure<E>;

// Helper to create success result
export function ok<T>(data: T): Success<T> {
  return { ok: true, data };
}

// Helper to create failure result
export function err<E>(error: E): Failure<E> {
  return { ok: false, error };
}

/**
 * Wrap an async function that might throw into a Result
 *
 * Useful for wrapping external APIs (Razorpay, Cashfree, Cloudinary, etc.)
 *
 * Usage:
 *   const result = await tryCatch(
 *     () => razorpay.subscriptions.create(options),
 *     Errors.PAYMENT_FAILED
 *   );
 */
export async function tryCatch<T>(
  fn: () => Promise<T>,
  errorOnFail: AppError
): Promise<Result<T, AppError>> {
  try {
    const data = await fn();
    return ok(data);
  } catch {
    return err(errorOnFail);
  }
}

/**
 * Unwrap a Result, throwing if it's an error
 *
 * Only use this when you KNOW it should succeed
 * (e.g., after a check, or in tests)
 */
export function unwrap<T>(result: Result<T, unknown>): T {
  if (!result.ok) {
    throw new Error('Unwrapped an error result');
  }
  return result.data;
}

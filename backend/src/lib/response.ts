/**
 * API Response Helpers
 *
 * Consistent response format across all endpoints:
 *
 * Success: { data: T }
 * Error:   { error: string, code: string, retryable?: boolean }
 *
 * The Flutter app expects these formats.
 */

import type { Context } from 'hono';
import type { ContentfulStatusCode } from 'hono/utils/http-status';
import type { AppError } from './errors';
import { getRequestId } from '../middleware/request-id';

// Type helper for Hono's status codes
type StatusCode = ContentfulStatusCode;

/**
 * Send a success response
 *
 * Usage:
 *   return success(c, user);
 *   return success(c, { merchants, total }, 200);
 */
export function success<T>(c: Context, data: T, status: StatusCode = 200) {
  return c.json({ data }, status);
}

/**
 * Send a created response (201)
 *
 * Usage:
 *   return created(c, newMerchant);
 */
export function created<T>(c: Context, data: T) {
  return c.json({ data }, 201);
}

/**
 * Send an error response from an AppError
 *
 * Usage:
 *   return apiError(c, Errors.USER_NOT_FOUND);
 */
export function apiError(c: Context, err: AppError) {
  const requestId = getRequestId(c);

  return c.json(
    {
      error: err.message,
      code: err.code,
      retryable: err.retryable,
      requestId, // Include for support tickets
    },
    err.httpStatus as StatusCode
  );
}

/**
 * Send an error response (flexible version)
 *
 * Usage:
 *   return error(c, Errors.USER_NOT_FOUND, 404);
 *   return error(c, Errors.VALIDATION_FAILED, 400, { details: {...} });
 */
export function error(
  c: Context,
  err: AppError | { code: string; message: string },
  status?: StatusCode,
  extra?: Record<string, unknown>
) {
  const requestId = getRequestId(c);
  const statusCode = (status ?? ('httpStatus' in err ? err.httpStatus : 500)) as StatusCode;

  return c.json(
    {
      error: err.message,
      code: err.code,
      retryable: 'retryable' in err ? err.retryable : false,
      requestId,
      ...extra,
    },
    statusCode
  );
}

/**
 * Send a validation error with field details
 *
 * Usage:
 *   return validationError(c, [
 *     { field: 'phone', message: 'Invalid phone format' },
 *     { field: 'name', message: 'Name is required' },
 *   ]);
 */
export function validationError(c: Context, fields: Array<{ field: string; message: string }>) {
  const requestId = getRequestId(c);

  return c.json(
    {
      error: 'Validation error',
      code: 'VALIDATION_ERROR',
      fields,
      retryable: false,
      requestId,
    },
    400
  );
}

/**
 * Log and return a Zod validation error
 *
 * Automatically logs the validation failure with request context.
 *
 * Usage:
 *   const parsed = schema.safeParse(body);
 *   if (!parsed.success) {
 *     return zodValidationError(c, parsed.error, body, 'createMerchant');
 *   }
 */
import { ZodError } from 'zod';
import { logger } from './logger';
import { Errors } from './errors';

export function zodValidationError(c: Context, zodError: ZodError, body: unknown, operation: string) {
  const requestId = getRequestId(c);
  const userId = c.get('userId') as string | undefined;
  const fieldErrors = zodError.flatten().fieldErrors;

  logger.warn(`Validation failed: ${operation}`, {
    requestId,
    userId,
    operation,
    body,
    errors: fieldErrors,
  });

  return error(c, Errors.VALIDATION_FAILED, 400, {
    details: fieldErrors,
  });
}

/**
 * Send a paginated response
 *
 * Usage:
 *   return paginated(c, {
 *     items: merchants,
 *     total: 100,
 *     page: 1,
 *     pageSize: 20,
 *   });
 */
export function paginated<T>(
  c: Context,
  data: {
    items: T[];
    total: number;
    page: number;
    pageSize: number;
  }
) {
  const { items, total, page, pageSize } = data;

  return c.json({
    data: items,
    pagination: {
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
      hasMore: page * pageSize < total,
    },
  });
}

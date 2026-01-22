/**
 * Standard Error Codes
 *
 * Consistent error responses across the API.
 * The Flutter app can switch on `code` to show appropriate UI.
 *
 * Format: { code, message, httpStatus }
 *
 * Error codes are grouped by category:
 * - AUTH_*      : Authentication/authorization
 * - USER_*      : User-related errors
 * - MERCHANT_*  : Merchant profile errors
 * - REWARD_*    : Reward configuration errors
 * - STAMP_*     : Stamp collection errors
 * - REDEMPTION_*: Redemption errors
 * - SUBSCRIPTION_*: Subscription errors
 * - PAYMENT_*   : Payment errors
 * - UPLOAD_*    : File upload errors
 * - SYSTEM_*    : Internal errors
 */

export interface AppError {
  code: string;
  message: string;
  httpStatus: number;
  retryable?: boolean; // Hint to client: should they retry?
}

// Error definitions
export const Errors = {
  // ============================================
  // Authentication
  // ============================================
  AUTH_INVALID_TOKEN: {
    code: 'AUTH_INVALID_TOKEN',
    message: 'Invalid token',
    httpStatus: 401,
    retryable: false,
  },
  AUTH_TOKEN_EXPIRED: {
    code: 'AUTH_TOKEN_EXPIRED',
    message: 'Token has expired. Please log in again.',
    httpStatus: 401,
    retryable: false,
  },
  AUTH_MISSING_TOKEN: {
    code: 'AUTH_MISSING_TOKEN',
    message: 'Authorization header required',
    httpStatus: 401,
    retryable: false,
  },
  AUTH_RATE_LIMITED: {
    code: 'AUTH_RATE_LIMITED',
    message: 'Too many attempts. Please wait before trying again.',
    httpStatus: 429,
    retryable: true,
  },
  AUTH_USER_NOT_FOUND: {
    code: 'AUTH_USER_NOT_FOUND',
    message: 'Account not found. Please log in again.',
    httpStatus: 401,
    retryable: false,
  },

  // OTP errors
  OTP_EXPIRED: {
    code: 'OTP_EXPIRED',
    message: 'OTP has expired. Please request a new one.',
    httpStatus: 400,
    retryable: false,
  },
  OTP_INVALID: {
    code: 'OTP_INVALID',
    message: 'Invalid OTP. Please check and try again.',
    httpStatus: 400,
    retryable: false,
  },
  OTP_MAX_ATTEMPTS: {
    code: 'OTP_MAX_ATTEMPTS',
    message: 'Too many incorrect attempts. Please request a new OTP.',
    httpStatus: 400,
    retryable: false,
  },
  OTP_SEND_FAILED: {
    code: 'OTP_SEND_FAILED',
    message: 'Failed to send OTP. Please try again.',
    httpStatus: 500,
    retryable: true,
  },
  OTP_ALREADY_SENT: {
    code: 'OTP_ALREADY_SENT',
    message: 'OTP already sent. Please wait before requesting again.',
    httpStatus: 429,
    retryable: false,
  },

  // ============================================
  // User
  // ============================================
  USER_NOT_FOUND: {
    code: 'USER_NOT_FOUND',
    message: 'User not found',
    httpStatus: 404,
    retryable: false,
  },
  USER_BANNED: {
    code: 'USER_BANNED',
    message: 'This account has been suspended. Contact support.',
    httpStatus: 403,
    retryable: false,
  },
  USER_PROFILE_INCOMPLETE: {
    code: 'USER_PROFILE_INCOMPLETE',
    message: 'Please complete your profile first.',
    httpStatus: 400,
    retryable: false,
  },

  // ============================================
  // Merchant
  // ============================================
  MERCHANT_NOT_FOUND: {
    code: 'MERCHANT_NOT_FOUND',
    message: 'Merchant not found',
    httpStatus: 404,
    retryable: false,
  },
  MERCHANT_NOT_ACTIVE: {
    code: 'MERCHANT_NOT_ACTIVE',
    message: 'This merchant is not currently active.',
    httpStatus: 400,
    retryable: false,
  },
  MERCHANT_NOT_VERIFIED: {
    code: 'MERCHANT_NOT_VERIFIED',
    message: 'Merchant verification pending.',
    httpStatus: 400,
    retryable: false,
  },
  MERCHANT_SUBSCRIPTION_EXPIRED: {
    code: 'MERCHANT_SUBSCRIPTION_EXPIRED',
    message: 'Your subscription has expired. Please renew to continue.',
    httpStatus: 403,
    retryable: false,
  },
  MERCHANT_NOT_OWNER: {
    code: 'MERCHANT_NOT_OWNER',
    message: 'You are not the owner of this merchant.',
    httpStatus: 403,
    retryable: false,
  },

  // ============================================
  // Reward
  // ============================================
  REWARD_NOT_FOUND: {
    code: 'REWARD_NOT_FOUND',
    message: 'Reward not found',
    httpStatus: 404,
    retryable: false,
  },
  REWARD_NOT_ACTIVE: {
    code: 'REWARD_NOT_ACTIVE',
    message: 'This reward is no longer available.',
    httpStatus: 400,
    retryable: false,
  },
  REWARD_LIMIT_REACHED: {
    code: 'REWARD_LIMIT_REACHED',
    message: 'Maximum number of rewards reached.',
    httpStatus: 400,
    retryable: false,
  },

  // ============================================
  // Stamp
  // ============================================
  STAMP_ALREADY_TODAY: {
    code: 'STAMP_ALREADY_TODAY',
    message: 'You have already collected a stamp today. Come back tomorrow!',
    httpStatus: 400,
    retryable: false,
  },
  STAMP_OUT_OF_RANGE: {
    code: 'STAMP_OUT_OF_RANGE',
    message: 'Please visit the restaurant to collect your stamp.',
    httpStatus: 400,
    retryable: false,
  },
  STAMP_CARD_NOT_FOUND: {
    code: 'STAMP_CARD_NOT_FOUND',
    message: 'Stamp card not found',
    httpStatus: 404,
    retryable: false,
  },
  STAMP_CARD_EXPIRED: {
    code: 'STAMP_CARD_EXPIRED',
    message: 'This stamp card has expired.',
    httpStatus: 400,
    retryable: false,
  },
  STAMP_CARD_ALREADY_COMPLETE: {
    code: 'STAMP_CARD_ALREADY_COMPLETE',
    message: 'This stamp card is already complete. Redeem your reward!',
    httpStatus: 400,
    retryable: false,
  },

  // ============================================
  // Redemption
  // ============================================
  REDEMPTION_NOT_FOUND: {
    code: 'REDEMPTION_NOT_FOUND',
    message: 'Redemption not found',
    httpStatus: 404,
    retryable: false,
  },
  REDEMPTION_NOT_READY: {
    code: 'REDEMPTION_NOT_READY',
    message: 'Stamp card is not complete yet.',
    httpStatus: 400,
    retryable: false,
  },
  REDEMPTION_ALREADY_CLAIMED: {
    code: 'REDEMPTION_ALREADY_CLAIMED',
    message: 'This reward has already been redeemed.',
    httpStatus: 400,
    retryable: false,
  },
  REDEMPTION_EXPIRED: {
    code: 'REDEMPTION_EXPIRED',
    message: 'This redemption has expired.',
    httpStatus: 400,
    retryable: false,
  },

  // ============================================
  // Subscription
  // ============================================
  SUBSCRIPTION_NOT_FOUND: {
    code: 'SUBSCRIPTION_NOT_FOUND',
    message: 'Subscription not found',
    httpStatus: 404,
    retryable: false,
  },
  SUBSCRIPTION_ALREADY_ACTIVE: {
    code: 'SUBSCRIPTION_ALREADY_ACTIVE',
    message: 'You already have an active subscription.',
    httpStatus: 400,
    retryable: false,
  },
  SUBSCRIPTION_CANCELLED: {
    code: 'SUBSCRIPTION_CANCELLED',
    message: 'Subscription has been cancelled.',
    httpStatus: 400,
    retryable: false,
  },

  // ============================================
  // Payment
  // ============================================
  PAYMENT_FAILED: {
    code: 'PAYMENT_FAILED',
    message: 'Payment failed. Please try again.',
    httpStatus: 400,
    retryable: true,
  },
  PAYMENT_SIGNATURE_INVALID: {
    code: 'PAYMENT_SIGNATURE_INVALID',
    message: 'Payment verification failed. Contact support if charged.',
    httpStatus: 400,
    retryable: false,
  },

  // ============================================
  // Upload
  // ============================================
  UPLOAD_TOO_LARGE: {
    code: 'UPLOAD_TOO_LARGE',
    message: 'File size exceeds the 5MB limit.',
    httpStatus: 400,
    retryable: false,
  },
  UPLOAD_INVALID_TYPE: {
    code: 'UPLOAD_INVALID_TYPE',
    message: 'Only JPEG, PNG, and WebP images are allowed.',
    httpStatus: 400,
    retryable: false,
  },
  UPLOAD_FAILED: {
    code: 'UPLOAD_FAILED',
    message: 'Failed to upload file. Please try again.',
    httpStatus: 500,
    retryable: true,
  },

  // ============================================
  // Validation
  // ============================================
  VALIDATION_ERROR: {
    code: 'VALIDATION_ERROR',
    message: 'Invalid request data.',
    httpStatus: 400,
    retryable: false,
  },
  VALIDATION_FAILED: {
    code: 'VALIDATION_FAILED',
    message: 'Request validation failed.',
    httpStatus: 400,
    retryable: false,
  },

  // ============================================
  // System
  // ============================================
  INTERNAL_ERROR: {
    code: 'INTERNAL_ERROR',
    message: 'Something went wrong. Please try again.',
    httpStatus: 500,
    retryable: true,
  },
  SERVICE_UNAVAILABLE: {
    code: 'SERVICE_UNAVAILABLE',
    message: 'Service temporarily unavailable. Please try again later.',
    httpStatus: 503,
    retryable: true,
  },
  MAINTENANCE_MODE: {
    code: 'MAINTENANCE_MODE',
    message: 'App is under maintenance. Please try again later.',
    httpStatus: 503,
    retryable: true,
  },
} as const;

// Type for error codes (for type safety)
export type ErrorCode = keyof typeof Errors;

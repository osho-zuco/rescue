/**
 * Validation Utilities
 *
 * Provides reusable Zod schemas and validation helpers.
 * All API input should be validated before processing.
 *
 * Security: Never trust client input!
 */

import { z } from 'zod';

// ============================================
// Common Schemas
// ============================================

/** Indian phone number: 10 digits, optionally prefixed with +91 */
export const phoneSchema = z
  .string()
  .transform((val) => val.replace(/\s+/g, '').replace(/^(\+91|91)/, ''))
  .pipe(z.string().length(10).regex(/^\d+$/, 'Invalid phone number'));

/** UUID v4 */
export const uuidSchema = z.string().uuid('Invalid ID format');

/** Pagination params */
export const paginationSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(20),
});

/** Date string (YYYY-MM-DD) */
export const dateSchema = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'Invalid date format (use YYYY-MM-DD)');

/** Price in rupees (positive number) */
export const priceSchema = z.coerce.number().int().min(0).max(100000);

/** Rating (1-5 stars) */
export const ratingSchema = z.coerce.number().int().min(1).max(5);

/** Latitude (-90 to 90) */
export const latitudeSchema = z.coerce.number().min(-90).max(90);

/** Longitude (-180 to 180) */
export const longitudeSchema = z.coerce.number().min(-180).max(180);

/** Coordinates object */
export const coordinatesSchema = z.object({
  latitude: latitudeSchema,
  longitude: longitudeSchema,
});

// ============================================
// Druto-Specific Schemas
// ============================================

/** User role */
export const userRoleSchema = z.enum(['CUSTOMER', 'MERCHANT_OWNER', 'ADMIN']);

/** Subscription status */
export const subscriptionStatusSchema = z.enum([
  'TRIAL',
  'ACTIVE',
  'PAST_DUE',
  'CANCELLED',
  'EXPIRED',
]);

/** Stamp card status */
export const stampCardStatusSchema = z.enum([
  'IN_PROGRESS',
  'READY_TO_REDEEM',
  'REDEEMED',
  'EXPIRED',
]);

/** Payment status */
export const paymentStatusSchema = z.enum(['PENDING', 'CAPTURED', 'FAILED', 'REFUNDED']);

// ============================================
// Request Body Schemas
// ============================================

/** Send OTP request */
export const sendOtpSchema = z.object({
  phone: phoneSchema,
});

/** Verify OTP request */
export const verifyOtpSchema = z.object({
  phone: phoneSchema,
  otp: z.string().length(6).regex(/^\d+$/, 'OTP must be 6 digits'),
});

/** Create/Update user profile */
export const updateUserSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  profilePhotoUrl: z.string().url().optional(),
});

/** Create merchant request */
export const createMerchantSchema = z.object({
  name: z.string().min(1).max(100),
  description: z.string().max(500).optional(),
  address: z.string().min(1).max(500),
  city: z.string().min(1).max(100),
  latitude: latitudeSchema,
  longitude: longitudeSchema,
  upiId: z.string().max(100).optional(),
});

/** Update merchant request */
export const updateMerchantSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  description: z.string().max(500).optional(),
  logoUrl: z.string().url().optional(),
  coverPhotoUrl: z.string().url().optional(),
  address: z.string().max(500).optional(),
  city: z.string().max(100).optional(),
  latitude: latitudeSchema.optional(),
  longitude: longitudeSchema.optional(),
  upiId: z.string().max(100).optional(),
});

/** Create reward request */
export const createRewardSchema = z.object({
  title: z.string().min(1).max(100),
  description: z.string().max(500).optional(),
  imageUrl: z.string().url().optional(),
  stampsRequired: z.number().int().min(1).max(50),
  expiryDays: z.number().int().min(1).max(365).optional(),
  requiresMinPurchase: z.boolean().default(false),
  minPurchaseAmount: z.number().int().min(0).optional(),
});

/** Update reward request */
export const updateRewardSchema = z.object({
  title: z.string().min(1).max(100).optional(),
  description: z.string().max(500).optional(),
  imageUrl: z.string().url().optional(),
  stampsRequired: z.number().int().min(1).max(50).optional(),
  expiryDays: z.number().int().min(1).max(365).nullable().optional(),
  requiresMinPurchase: z.boolean().optional(),
  minPurchaseAmount: z.number().int().min(0).nullable().optional(),
  isActive: z.boolean().optional(),
});

/** Collect stamp request */
export const collectStampSchema = z.object({
  merchantId: uuidSchema,
  rewardId: uuidSchema,
  latitude: latitudeSchema.optional(),
  longitude: longitudeSchema.optional(),
});

/** Redeem reward request */
export const redeemRewardSchema = z.object({
  stampCardId: uuidSchema,
});

/** Verify redemption (merchant side) */
export const verifyRedemptionSchema = z.object({
  redemptionId: uuidSchema,
});

/** Search merchants request */
export const searchMerchantsSchema = z
  .object({
    latitude: latitudeSchema.optional(),
    longitude: longitudeSchema.optional(),
    radiusKm: z.coerce.number().min(1).max(50).default(10),
    query: z.string().max(100).optional(),
    city: z.string().max(100).optional(),
  })
  .merge(paginationSchema);

/** Create review request */
export const createReviewSchema = z.object({
  merchantId: uuidSchema,
  rating: ratingSchema,
  comment: z.string().max(500).optional(),
});

// ============================================
// Helper Functions
// ============================================

/**
 * Sanitize string input (trim, remove dangerous chars)
 * Use for free-text fields to prevent XSS
 */
export function sanitizeString(input: string): string {
  return input
    .trim()
    .replace(/[<>]/g, '') // Remove angle brackets
    .slice(0, 10000); // Limit length
}

/**
 * Parse and validate, returning Result instead of throwing
 */
export function safeValidate<T>(
  schema: z.ZodSchema<T>,
  data: unknown
): { success: true; data: T } | { success: false; errors: z.ZodError } {
  const result = schema.safeParse(data);
  if (result.success) {
    return { success: true, data: result.data };
  }
  return { success: false, errors: result.error };
}

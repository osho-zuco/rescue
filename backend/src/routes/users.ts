/**
 * Users Routes
 *
 * GET  /users/me       - Get current user profile
 * PATCH /users/me      - Update current user profile
 */

import { Hono } from 'hono';
import { z } from 'zod';
import { prisma } from '../db';
import { authMiddleware, getUserId } from '../middleware/auth';
import { success, apiError, zodValidationError } from '../lib/response';
import { Errors } from '../lib/errors';
import { logger } from '../lib/logger';

const users = new Hono();

// All routes require authentication
users.use('*', authMiddleware);

// ============================================
// Schemas
// ============================================

const updateProfileSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  profilePhotoUrl: z.string().url().optional(),
});

// ============================================
// Routes
// ============================================

/**
 * GET /users/me
 *
 * Get current authenticated user's profile.
 */
users.get('/me', async (c) => {
  const userId = getUserId(c);

  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        phone: true,
        name: true,
        profilePhotoUrl: true,
        role: true,
        createdAt: true,
        // Include owned merchants if MERCHANT_OWNER
        ownedMerchants: {
          select: {
            id: true,
            name: true,
            logoUrl: true,
            isActive: true,
            subscriptionStatus: true,
          },
        },
        // Stats
        _count: {
          select: {
            stampCards: true,
            redemptions: true,
          },
        },
      },
    });

    if (!user) {
      return apiError(c, Errors.USER_NOT_FOUND);
    }

    return success(c, {
      id: user.id,
      phone: user.phone,
      name: user.name,
      profilePhotoUrl: user.profilePhotoUrl,
      role: user.role,
      createdAt: user.createdAt,
      merchants: user.ownedMerchants,
      stats: {
        totalStampCards: user._count.stampCards,
        totalRedemptions: user._count.redemptions,
      },
    });
  } catch (error) {
    logger.error('Failed to get user profile', { userId, error });
    return apiError(c, Errors.INTERNAL_ERROR);
  }
});

/**
 * PATCH /users/me
 *
 * Update current user's profile.
 */
users.patch('/me', async (c) => {
  const userId = getUserId(c);
  const body = await c.req.json();
  const parsed = updateProfileSchema.safeParse(body);

  if (!parsed.success) {
    return zodValidationError(c, parsed.error, body, 'updateProfile');
  }

  const { name, profilePhotoUrl } = parsed.data;

  // Check if there's anything to update
  if (!name && !profilePhotoUrl) {
    return apiError(c, {
      code: 'NO_CHANGES',
      message: 'No changes provided',
      httpStatus: 400,
    });
  }

  try {
    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        ...(name && { name }),
        ...(profilePhotoUrl && { profilePhotoUrl }),
      },
      select: {
        id: true,
        phone: true,
        name: true,
        profilePhotoUrl: true,
        role: true,
      },
    });

    logger.info('User profile updated', { userId });

    return success(c, user);
  } catch (error) {
    logger.error('Failed to update user profile', { userId, error });
    return apiError(c, Errors.INTERNAL_ERROR);
  }
});

export default users;

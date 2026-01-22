/**
 * Auth Routes
 *
 * POST /auth/otp/send    - Send OTP to phone
 * POST /auth/otp/verify  - Verify OTP and get token
 * POST /auth/otp/resend  - Resend OTP
 * POST /auth/refresh     - Refresh access token
 */

import { Hono } from 'hono';
import { z } from 'zod';
import { prisma } from '../db';
import { getOtpProvider } from '../services/otp';
import { signToken, signRefreshToken, verifyRefreshToken } from '../lib/jwt';
import { success, created, apiError, zodValidationError } from '../lib/response';
import { Errors } from '../lib/errors';
import { logger } from '../lib/logger';

const auth = new Hono();

// ============================================
// Schemas
// ============================================

const sendOtpSchema = z.object({
  phone: z
    .string()
    .regex(/^\d{10}$/, 'Phone must be 10 digits'),
});

const verifyOtpSchema = z.object({
  phone: z
    .string()
    .regex(/^\d{10}$/, 'Phone must be 10 digits'),
  otp: z
    .string()
    .regex(/^\d{6}$/, 'OTP must be 6 digits'),
});

const resendOtpSchema = z.object({
  phone: z
    .string()
    .regex(/^\d{10}$/, 'Phone must be 10 digits'),
  channel: z.enum(['sms', 'voice']).optional(),
});

const refreshTokenSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token is required'),
});

// ============================================
// Routes
// ============================================

/**
 * POST /auth/otp/send
 *
 * Send OTP to phone number.
 */
auth.post('/otp/send', async (c) => {
  const body = await c.req.json();
  const parsed = sendOtpSchema.safeParse(body);

  if (!parsed.success) {
    return zodValidationError(c, parsed.error, body, 'sendOtp');
  }

  const { phone } = parsed.data;

  try {
    const otpProvider = getOtpProvider();
    const result = await otpProvider.sendOtp({ phone });

    if (!result.ok) {
      logger.error('OTP send failed', {
        phone: phone.slice(-4), // Log only last 4 digits
        error: result.error,
      });
      return apiError(c, {
        code: result.error.code,
        message: result.error.message,
        httpStatus: result.error.httpStatus,
      });
    }

    logger.info('OTP sent', {
      phone: phone.slice(-4),
      provider: result.data.provider,
    });

    return success(c, {
      message: 'OTP sent successfully',
      verificationId: result.data.verificationId,
    });
  } catch (error) {
    logger.error('OTP send error', { error });
    return apiError(c, Errors.OTP_SEND_FAILED);
  }
});

/**
 * POST /auth/otp/verify
 *
 * Verify OTP and return JWT tokens.
 * Creates user if doesn't exist (phone-based signup).
 */
auth.post('/otp/verify', async (c) => {
  const body = await c.req.json();
  const parsed = verifyOtpSchema.safeParse(body);

  if (!parsed.success) {
    return zodValidationError(c, parsed.error, body, 'verifyOtp');
  }

  const { phone, otp } = parsed.data;

  try {
    // Verify OTP with provider
    const otpProvider = getOtpProvider();
    const result = await otpProvider.verifyOtp({ phone, otp });

    if (!result.ok) {
      logger.warn('OTP verification failed', {
        phone: phone.slice(-4),
        error: result.error.code,
      });
      return apiError(c, {
        code: result.error.code,
        message: result.error.message,
        httpStatus: result.error.httpStatus,
      });
    }

    if (!result.data.valid) {
      return apiError(c, Errors.OTP_INVALID);
    }

    // Find or create user
    let user = await prisma.user.findUnique({
      where: { phone },
    });

    const isNewUser = !user;

    if (!user) {
      user = await prisma.user.create({
        data: {
          phone,
          role: 'CUSTOMER', // Default role
        },
      });

      logger.info('New user created', {
        userId: user.id,
        phone: phone.slice(-4),
      });
    }

    // Generate tokens
    const token = signToken({
      userId: user.id,
      role: user.role,
    });

    const refreshToken = signRefreshToken({
      userId: user.id,
      role: user.role,
    });

    logger.info('User logged in', {
      userId: user.id,
      isNewUser,
    });

    return success(c, {
      token,
      refreshToken,
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
        profilePhotoUrl: user.profilePhotoUrl,
        role: user.role,
      },
      isNewUser,
    });
  } catch (error) {
    logger.error('OTP verify error', { error });
    return apiError(c, Errors.INTERNAL_ERROR);
  }
});

/**
 * POST /auth/otp/resend
 *
 * Resend OTP (retry).
 */
auth.post('/otp/resend', async (c) => {
  const body = await c.req.json();
  const parsed = resendOtpSchema.safeParse(body);

  if (!parsed.success) {
    return zodValidationError(c, parsed.error, body, 'resendOtp');
  }

  const { phone, channel } = parsed.data;

  try {
    const otpProvider = getOtpProvider();
    const result = await otpProvider.resendOtp({ phone, channel });

    if (!result.ok) {
      logger.error('OTP resend failed', {
        phone: phone.slice(-4),
        error: result.error,
      });
      return apiError(c, {
        code: result.error.code,
        message: result.error.message,
        httpStatus: result.error.httpStatus,
      });
    }

    logger.info('OTP resent', {
      phone: phone.slice(-4),
      channel: channel || 'sms',
    });

    return success(c, {
      message: 'OTP sent successfully',
      verificationId: result.data.verificationId,
    });
  } catch (error) {
    logger.error('OTP resend error', { error });
    return apiError(c, Errors.OTP_SEND_FAILED);
  }
});

/**
 * POST /auth/refresh
 *
 * Refresh access token using refresh token.
 */
auth.post('/refresh', async (c) => {
  const body = await c.req.json();
  const parsed = refreshTokenSchema.safeParse(body);

  if (!parsed.success) {
    return zodValidationError(c, parsed.error, body, 'refreshToken');
  }

  const { refreshToken } = parsed.data;

  try {
    // Verify refresh token
    const result = verifyRefreshToken(refreshToken);

    if (!result.ok) {
      return apiError(c, result.error);
    }

    const { userId, role } = result.data;

    // Check user still exists and is valid
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      return apiError(c, Errors.USER_NOT_FOUND);
    }

    // Generate new tokens
    const newToken = signToken({
      userId: user.id,
      role: user.role, // Use current role (may have changed)
    });

    const newRefreshToken = signRefreshToken({
      userId: user.id,
      role: user.role,
    });

    return success(c, {
      token: newToken,
      refreshToken: newRefreshToken,
    });
  } catch (error) {
    logger.error('Token refresh error', { error });
    return apiError(c, Errors.AUTH_INVALID_TOKEN);
  }
});

export default auth;

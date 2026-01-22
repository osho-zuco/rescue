/**
 * Druto Backend - Entry Point
 *
 * Bun + Hono API server for the Druto loyalty platform.
 */

import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { config } from './config';
import { requestIdMiddleware } from './middleware/request-id';
import { apiRateLimit, authRateLimit } from './middleware/rate-limit';
import { initOtpService } from './services/otp';
import { logger } from './lib/logger';

// Routes
import authRoutes from './routes/auth';
import usersRoutes from './routes/users';
import merchantsRoutes from './routes/merchants';
import rewardsRoutes from './routes/rewards';
import stampsRoutes from './routes/stamps';
import redemptionsRoutes from './routes/redemptions';

// ============================================
// Initialize Services
// ============================================

// Initialize OTP provider (Twilio/MSG91)
initOtpService();
logger.info(`OTP service initialized: ${config.otpProvider}`);

// ============================================
// Create App
// ============================================

const app = new Hono();

// ============================================
// Global Middleware
// ============================================

// Request ID for tracing
app.use('*', requestIdMiddleware);

// CORS
app.use(
  '*',
  cors({
    origin: config.cors.origin,
    allowMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowHeaders: ['Content-Type', 'Authorization'],
    exposeHeaders: ['X-Request-ID'],
    maxAge: 86400, // 24 hours
  })
);

// Rate limiting
app.use('*', apiRateLimit);

// Stricter rate limit for auth endpoints
app.use('/api/v1/auth/*', authRateLimit);

// ============================================
// Health Check
// ============================================

app.get('/health', (c) => {
  return c.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  });
});

// ============================================
// API Routes
// ============================================

const v1 = new Hono();

// Auth (public)
v1.route('/auth', authRoutes);

// Users (authenticated)
v1.route('/users', usersRoutes);

// Merchants (mixed auth)
v1.route('/merchants', merchantsRoutes);

// Rewards (mixed auth) - includes /merchants/:id/rewards routes
v1.route('/', rewardsRoutes);

// Stamps (authenticated)
v1.route('/stamps', stampsRoutes);

// Redemptions (authenticated) - includes /stamp-cards/:id/redeem and /redemptions/* routes
v1.route('/', redemptionsRoutes);

// Mount v1 routes
app.route('/api/v1', v1);

// ============================================
// 404 Handler
// ============================================

app.notFound((c) => {
  return c.json(
    {
      error: 'Not found',
      code: 'NOT_FOUND',
    },
    404
  );
});

// ============================================
// Error Handler
// ============================================

app.onError((err, c) => {
  logger.error('Unhandled error', {
    error: err.message,
    stack: err.stack,
    path: c.req.path,
    method: c.req.method,
  });

  return c.json(
    {
      error: 'Something went wrong',
      code: 'INTERNAL_ERROR',
    },
    500
  );
});

// ============================================
// Start Server
// ============================================

const port = config.server.port;

logger.info(`Starting Druto API server`, {
  port,
  env: config.server.nodeEnv,
  otpProvider: config.otpProvider,
  paymentProvider: config.paymentProvider,
});

export default {
  port,
  fetch: app.fetch,
};

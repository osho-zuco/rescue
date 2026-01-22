/**
 * Application Configuration
 *
 * All configurable values are read from environment variables.
 * Bun automatically loads .env files - no dotenv needed!
 *
 * Environments:
 * - development: Local machine (NODE_ENV=development or unset)
 * - staging: Railway staging project (NODE_ENV=staging)
 * - production: Railway production project (NODE_ENV=production)
 */

type Environment = 'development' | 'staging' | 'production';

const nodeEnv = (Bun.env.NODE_ENV || 'development') as Environment;
const isProduction = nodeEnv === 'production';
const isStaging = nodeEnv === 'staging';
const isDevelopment = nodeEnv === 'development';

// Staging and production both require proper configuration
const requiresValidation = isProduction || isStaging;

/**
 * Validate required environment variables
 * Fails fast in staging/production if critical vars are missing
 */
function requireEnv(name: string, defaultValue?: string): string {
  const value = Bun.env[name] || defaultValue;

  if (!value && requiresValidation) {
    throw new Error(`❌ Missing required environment variable: ${name}`);
  }

  return value || '';
}

/**
 * Validate JWT secret is secure in staging/production
 */
function getJwtSecret(): string {
  const secret = Bun.env.JWT_SECRET;

  if (requiresValidation) {
    if (!secret) {
      throw new Error(`❌ JWT_SECRET is required in ${nodeEnv}`);
    }
    if (secret.length < 32) {
      throw new Error(`❌ JWT_SECRET must be at least 32 characters in ${nodeEnv}`);
    }
  }

  // In development, use a default (but warn)
  if (!secret) {
    console.warn('⚠️  Using default JWT_SECRET - DO NOT use in staging/production!');
    return 'dev-secret-change-in-production-min-32-chars';
  }

  return secret;
}

export const config = {
  // Server
  server: {
    port: parseInt(Bun.env.PORT || '3000'),
    nodeEnv,
    isProduction,
    isStaging,
    isDevelopment,
    requiresValidation,
  },

  // JWT (validated)
  jwt: {
    secret: getJwtSecret(),
    expiresIn: Bun.env.JWT_EXPIRES_IN || '30d',
  },

  // Feature Flags
  features: {
    // Manual approval mode: merchants need admin approval to go live
    manualApproval: Bun.env.MANUAL_APPROVAL !== 'false', // Default: true
  },

  // Subscription Plans
  subscription: {
    trialDays: parseInt(Bun.env.TRIAL_DAYS || '14'),
    monthlyPriceRupees: parseInt(Bun.env.MONTHLY_PRICE_RUPEES || '199'),
  },

  // Stamp Collection
  stamps: {
    // Geofence radius in meters for stamp collection
    geofenceRadiusMeters: parseInt(Bun.env.GEOFENCE_RADIUS_METERS || '50'),
    // Max stamps per merchant per day per user
    maxStampsPerDay: parseInt(Bun.env.MAX_STAMPS_PER_DAY || '1'),
  },

  // Search
  search: {
    defaultRadiusKm: parseInt(Bun.env.DEFAULT_SEARCH_RADIUS_KM || '10'),
    maxRadiusKm: parseInt(Bun.env.MAX_SEARCH_RADIUS_KM || '50'),
  },

  // External Services
  firebase: {
    projectId: Bun.env.FIREBASE_PROJECT_ID,
    privateKey: Bun.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    clientEmail: Bun.env.FIREBASE_CLIENT_EMAIL,
  },

  // Payment Gateway Selection: 'razorpay' | 'cashfree'
  paymentProvider: (Bun.env.PAYMENT_PROVIDER || 'razorpay') as 'razorpay' | 'cashfree',

  // Razorpay
  razorpay: {
    keyId: Bun.env.RAZORPAY_KEY_ID,
    keySecret: Bun.env.RAZORPAY_KEY_SECRET,
    webhookSecret: Bun.env.RAZORPAY_WEBHOOK_SECRET,
    mockMode: Bun.env.RAZORPAY_MOCK_MODE === 'true' || isDevelopment,
  },

  // Cashfree
  cashfree: {
    appId: Bun.env.CASHFREE_APP_ID,
    secretKey: Bun.env.CASHFREE_SECRET_KEY,
    webhookSecret: Bun.env.CASHFREE_WEBHOOK_SECRET,
    mockMode: Bun.env.CASHFREE_MOCK_MODE === 'true' || isDevelopment,
    useSandbox: nodeEnv !== 'production',
    get baseUrl() {
      return this.useSandbox
        ? 'https://sandbox.cashfree.com/pg'
        : 'https://api.cashfree.com/pg';
    },
  },

  // OTP Provider Selection: 'twilio' | 'msg91'
  otpProvider: (Bun.env.OTP_PROVIDER || 'msg91') as 'twilio' | 'msg91',

  // Twilio Verify Service
  twilio: {
    accountSid: Bun.env.TWILIO_ACCOUNT_SID,
    authToken: Bun.env.TWILIO_AUTH_TOKEN,
    verifyServiceSid: Bun.env.TWILIO_VERIFY_SERVICE_SID,
    mockMode: Bun.env.TWILIO_MOCK_MODE === 'true',
    reservedTestNumbers: (Bun.env.TWILIO_RESERVED_TEST_NUMBERS || '')
      .split(',')
      .map((n) => n.trim())
      .filter((n) => n.length === 10 && /^\d{10}$/.test(n)),
    reservedTestOtp: Bun.env.TWILIO_RESERVED_TEST_OTP || '123456',
  },

  // MSG91 OTP Service (cheaper for India)
  msg91: {
    authKey: Bun.env.MSG91_AUTH_KEY,
    templateId: Bun.env.MSG91_TEMPLATE_ID,
    mockMode: Bun.env.MSG91_MOCK_MODE === 'true',
    reservedTestNumbers: (Bun.env.MSG91_RESERVED_TEST_NUMBERS || '')
      .split(',')
      .map((n) => n.trim())
      .filter((n) => n.length === 10 && /^\d{10}$/.test(n)),
    reservedTestOtp: Bun.env.MSG91_RESERVED_TEST_OTP || '123456',
  },

  cloudinary: {
    cloudName: Bun.env.CLOUDINARY_CLOUD_NAME,
    apiKey: Bun.env.CLOUDINARY_API_KEY,
    apiSecret: Bun.env.CLOUDINARY_API_SECRET,
  },

  mixpanel: {
    token: Bun.env.MIXPANEL_TOKEN,
  },

  // CORS
  cors: {
    origin: requiresValidation ? Bun.env.CORS_ORIGIN || 'https://getdruto.com' : '*',
  },

  // Sentry
  sentry: {
    dsn: Bun.env.SENTRY_DSN,
    enabled: requiresValidation || Bun.env.SENTRY_ENABLED === 'true',
  },
};

// Log config on startup (hide sensitive values)
if (config.server.nodeEnv === 'development') {
  console.log('Config loaded:', {
    features: config.features,
    subscription: config.subscription,
    stamps: config.stamps,
    search: config.search,
    paymentProvider: config.paymentProvider,
    otpProvider: config.otpProvider,
  });
}

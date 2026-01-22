/**
 * OTP Provider Factory (SOLID: Factory Pattern)
 *
 * Creates the appropriate OTP provider based on configuration.
 * Single point of change when adding new providers.
 */

import { config } from '../../config';
import { logger } from '../../lib/logger';
import type { IOtpProvider, OtpProvider } from './IOtpProvider';
import { TwilioProvider } from './TwilioProvider';
import { Msg91Provider } from './Msg91Provider';

// Singleton instance
let otpProvider: IOtpProvider | null = null;

/**
 * Get the configured OTP provider instance
 * Creates and initializes on first call (lazy initialization)
 */
export function getOtpProvider(): IOtpProvider {
  if (!otpProvider) {
    otpProvider = createOtpProvider(config.otpProvider);
    otpProvider.init();
  }
  return otpProvider;
}

/**
 * Create OTP provider instance based on type
 * Does NOT initialize - call init() separately
 */
export function createOtpProvider(type: OtpProvider): IOtpProvider {
  logger.info(`Creating OTP provider: ${type}`);

  switch (type) {
    case 'msg91':
      return new Msg91Provider();
    case 'twilio':
    default:
      return new TwilioProvider();
  }
}

/**
 * Initialize OTP service
 * Call once at server startup
 */
export function initOtpService(): void {
  const provider = getOtpProvider();
  if (!provider.isInitialized()) {
    provider.init();
  }
}

/**
 * Check if OTP service is available
 */
export function isOtpServiceInitialized(): boolean {
  return otpProvider?.isInitialized() ?? false;
}

/**
 * Get current provider ID
 */
export function getCurrentProviderId(): OtpProvider {
  return getOtpProvider().providerId;
}

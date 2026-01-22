/**
 * OTP Service - Public API
 *
 * Re-exports everything needed by consumers.
 * Import from 'services/otp' not individual files.
 */

// Types
export type {
  IOtpProvider,
  OtpProvider,
  SendOtpParams,
  SendOtpResponse,
  VerifyOtpParams,
  VerifyOtpResponse,
  ResendOtpParams,
  OtpError,
} from './IOtpProvider';

// Factory & initialization
export {
  getOtpProvider,
  createOtpProvider,
  initOtpService,
  isOtpServiceInitialized,
  getCurrentProviderId,
} from './OtpProviderFactory';

// Concrete implementations (rarely needed directly)
export { TwilioProvider } from './TwilioProvider';
export { Msg91Provider } from './Msg91Provider';

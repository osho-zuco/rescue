/**
 * OTP Provider Interface (SOLID: Dependency Inversion Principle)
 *
 * Abstract contract for all OTP provider implementations.
 * Adding a new provider requires NO changes to routes - just implement this interface.
 */

import { Result } from '../../lib/result';

// ============================================
// Unified Types
// ============================================

export type OtpProvider = 'twilio' | 'msg91';

export interface SendOtpParams {
  phone: string; // 10 digits, without country code
}

export interface SendOtpResponse {
  provider: OtpProvider;
  verificationId: string; // Provider's request/verification ID
}

export interface VerifyOtpParams {
  phone: string; // 10 digits
  otp: string; // 6 digit OTP
}

export interface VerifyOtpResponse {
  valid: boolean;
  verificationId: string;
}

export interface ResendOtpParams {
  phone: string;
  channel?: 'sms' | 'voice'; // SMS or voice call
}

export interface OtpError {
  code: string;
  message: string;
  httpStatus: number;
  retryable: boolean;
}

// ============================================
// OTP Provider Interface
// ============================================

/**
 * Abstract OTP provider interface.
 * Each concrete implementation (Twilio, MSG91, etc.)
 * must implement all these methods.
 */
export interface IOtpProvider {
  /**
   * Provider identifier
   */
  readonly providerId: OtpProvider;

  /**
   * Initialize the provider
   * Call once at server startup
   */
  init(): void;

  /**
   * Check if provider is initialized and available
   */
  isInitialized(): boolean;

  /**
   * Send OTP to phone number
   * Provider handles OTP generation and delivery
   */
  sendOtp(params: SendOtpParams): Promise<Result<SendOtpResponse, OtpError>>;

  /**
   * Verify OTP entered by user
   */
  verifyOtp(params: VerifyOtpParams): Promise<Result<VerifyOtpResponse, OtpError>>;

  /**
   * Resend OTP (retry)
   * Some providers have dedicated retry endpoints
   */
  resendOtp(params: ResendOtpParams): Promise<Result<SendOtpResponse, OtpError>>;
}

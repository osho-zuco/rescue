/**
 * Twilio OTP Provider Implementation (SOLID: Open/Closed Principle)
 *
 * Concrete implementation of IOtpProvider for Twilio Verify.
 * No modifications needed when adding new providers.
 *
 * Cost: ~₹12/OTP (Verify fee + SMS delivery)
 */

import twilio from 'twilio';
import { config } from '../../config';
import { logger } from '../../lib/logger';
import { ok, err } from '../../lib/result';
import { Errors } from '../../lib/errors';
import type {
  IOtpProvider,
  SendOtpParams,
  SendOtpResponse,
  VerifyOtpParams,
  VerifyOtpResponse,
  ResendOtpParams,
  OtpError,
} from './IOtpProvider';
import type { Result } from '../../lib/result';

export class TwilioProvider implements IOtpProvider {
  readonly providerId = 'twilio' as const;

  private isInit = false;
  private client: ReturnType<typeof twilio> | null = null;

  private get useMockAuth(): boolean {
    return config.twilio.mockMode;
  }

  private get reservedTestNumbers(): string[] {
    return config.twilio.reservedTestNumbers;
  }

  private get reservedTestOtp(): string {
    return config.twilio.reservedTestOtp;
  }

  /**
   * Initialize Twilio client
   */
  init(): void {
    if (this.isInit) {
      logger.debug('Twilio already initialized');
      return;
    }

    const { accountSid, authToken, verifyServiceSid } = config.twilio;

    if (this.useMockAuth) {
      this.isInit = true;
      logger.info('Twilio OTP provider initialized (MOCK MODE - OTP: 123456)');
      return;
    }

    if (!accountSid || !authToken) {
      logger.warn('Twilio credentials not configured - OTP features disabled');
      return;
    }

    if (!verifyServiceSid) {
      logger.warn('Twilio Verify Service SID not configured');
      return;
    }

    this.client = twilio(accountSid, authToken);
    this.isInit = true;
    logger.info('Twilio OTP provider initialized');
  }

  isInitialized(): boolean {
    return this.isInit;
  }

  /**
   * Send OTP via Twilio Verify
   */
  async sendOtp(
    params: SendOtpParams
  ): Promise<Result<SendOtpResponse, OtpError>> {
    if (!this.isInit && !this.useMockAuth) {
      logger.error('Twilio not initialized - cannot send OTP');
      return err(Errors.SERVICE_UNAVAILABLE as OtpError);
    }

    const { verifyServiceSid } = config.twilio;
    const cleanPhone = params.phone.replace(/\D/g, '');

    // Validate phone
    if (cleanPhone.length !== 10) {
      return err({
        code: 'INVALID_PHONE',
        message: 'Phone number must be 10 digits',
        httpStatus: 400,
        retryable: false,
      });
    }

    // Check reserved test numbers
    const isReservedTestNumber =
      this.reservedTestNumbers.length > 0 &&
      this.reservedTestNumbers.includes(cleanPhone);

    if (isReservedTestNumber || this.useMockAuth) {
      logger.info(
        this.useMockAuth
          ? 'MOCK MODE - OTP for testing'
          : 'RESERVED TEST NUMBER - OTP for app store reviewers',
        {
          phone: `+91${cleanPhone.slice(-4)}`,
          otp: this.useMockAuth ? '123456' : this.reservedTestOtp,
          env: config.server.nodeEnv,
        }
      );
      return ok({
        provider: 'twilio',
        verificationId: `reserved-test-${Date.now()}`,
      });
    }

    try {
      const verification = await this.client!.verify.v2
        .services(verifyServiceSid!)
        .verifications.create({
          to: `+91${cleanPhone}`,
          channel: 'sms',
        });

      if (verification.status === 'pending') {
        logger.info('OTP sent successfully via Twilio', {
          phone: `***${cleanPhone.slice(-4)}`,
          sid: verification.sid,
        });
        return ok({
          provider: 'twilio',
          verificationId: verification.sid,
        });
      }

      logger.error('Unexpected Twilio response', { status: verification.status });
      return err({
        code: 'OTP_SEND_FAILED',
        message: 'Failed to send OTP. Please try again.',
        httpStatus: 500,
        retryable: true,
      });
    } catch (error: any) {
      logger.error('Twilio API error', {
        error: error.message || 'Unknown error',
        code: error.code,
      });

      return err({
        code: 'OTP_SEND_FAILED',
        message: this.mapTwilioError(error.code, error.message),
        httpStatus: error.status || 500,
        retryable: this.isRetryableError(error.code),
      });
    }
  }

  /**
   * Verify OTP via Twilio Verify
   */
  async verifyOtp(
    params: VerifyOtpParams
  ): Promise<Result<VerifyOtpResponse, OtpError>> {
    if (!this.isInit && !this.useMockAuth) {
      return err(Errors.SERVICE_UNAVAILABLE as OtpError);
    }

    const { verifyServiceSid } = config.twilio;
    const cleanPhone = params.phone.replace(/\D/g, '');

    // Check reserved test numbers
    const isReservedTestNumber =
      this.reservedTestNumbers.length > 0 &&
      this.reservedTestNumbers.includes(cleanPhone);

    if (isReservedTestNumber || this.useMockAuth) {
      const isValid = this.useMockAuth
        ? params.otp === '123456'
        : params.otp === this.reservedTestOtp;

      logger.info(
        this.useMockAuth
          ? 'MOCK MODE - OTP verification'
          : 'RESERVED TEST NUMBER - OTP verification',
        {
          phone: `+91${cleanPhone.slice(-4)}`,
          valid: isValid,
        }
      );

      if (!isValid) {
        return err(Errors.OTP_INVALID as OtpError);
      }

      return ok({
        valid: true,
        verificationId: `reserved-test-${Date.now()}`,
      });
    }

    try {
      const verificationCheck = await this.client!.verify.v2
        .services(verifyServiceSid!)
        .verificationChecks.create({
          to: `+91${cleanPhone}`,
          code: params.otp,
        });

      if (verificationCheck.status === 'approved' && verificationCheck.valid) {
        logger.info('OTP verified successfully via Twilio', {
          phone: `***${cleanPhone.slice(-4)}`,
          sid: verificationCheck.sid,
        });
        return ok({
          valid: true,
          verificationId: verificationCheck.sid,
        });
      }

      logger.warn('Invalid OTP entered', {
        phone: `***${cleanPhone.slice(-4)}`,
        status: verificationCheck.status,
      });
      return err(Errors.OTP_INVALID as OtpError);
    } catch (error: any) {
      logger.error('Twilio verify API error', {
        error: error.message || 'Unknown error',
        code: error.code,
      });

      if (error.code === 60200) {
        return err(Errors.OTP_INVALID as OtpError);
      }
      if (error.code === 60202) {
        return err(Errors.OTP_EXPIRED as OtpError);
      }
      if (error.code === 60203) {
        return err({
          code: 'TOO_MANY_ATTEMPTS',
          message: 'Too many failed attempts. Please request a new OTP.',
          httpStatus: 429,
          retryable: false,
        });
      }

      return err({
        code: 'OTP_VERIFICATION_FAILED',
        message: this.mapTwilioError(error.code, error.message),
        httpStatus: error.status || 500,
        retryable: false,
      });
    }
  }

  /**
   * Resend OTP - Twilio just sends a new one
   */
  async resendOtp(
    params: ResendOtpParams
  ): Promise<Result<SendOtpResponse, OtpError>> {
    return this.sendOtp({ phone: params.phone });
  }

  // ============================================
  // Helpers
  // ============================================

  private mapTwilioError(code?: number, message?: string): string {
    if (!code) return message || 'An error occurred';

    switch (code) {
      case 60200:
        return 'Invalid OTP. Please check and try again.';
      case 60202:
        return 'OTP has expired. Please request a new one.';
      case 60203:
        return 'Too many failed attempts. Please try again later.';
      case 60212:
        return 'Too many attempts. Please try again in a few minutes.';
      case 60223:
        return 'Phone number cannot receive SMS. Please use a different number.';
      case 60410:
        return 'Invalid phone number format.';
      case 21211:
        return 'Invalid phone number.';
      case 21408:
        return 'Service not available in this region.';
      case 21614:
        return 'Phone number cannot receive verification codes.';
      default:
        return message || 'Verification failed. Please try again.';
    }
  }

  private isRetryableError(code?: number): boolean {
    if (!code) return true;

    const nonRetryable = [60200, 60203, 60410, 21211, 21614];
    return !nonRetryable.includes(code);
  }
}

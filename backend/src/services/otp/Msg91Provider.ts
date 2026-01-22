/**
 * MSG91 OTP Provider Implementation (SOLID: Open/Closed Principle)
 *
 * Concrete implementation of IOtpProvider for MSG91.
 * No modifications needed when adding new providers.
 *
 * Cost: ~₹0.25/OTP (DLT compliant, India-focused)
 */

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

export class Msg91Provider implements IOtpProvider {
  readonly providerId = 'msg91' as const;

  private isInit = false;

  private get useMockAuth(): boolean {
    return config.msg91.mockMode;
  }

  private get reservedTestNumbers(): string[] {
    return config.msg91.reservedTestNumbers;
  }

  private get reservedTestOtp(): string {
    return config.msg91.reservedTestOtp;
  }

  /**
   * Initialize MSG91 service
   */
  init(): void {
    if (this.isInit) {
      logger.debug('MSG91 already initialized');
      return;
    }

    const { authKey, templateId } = config.msg91;

    if (this.useMockAuth) {
      this.isInit = true;
      logger.info('MSG91 OTP provider initialized (MOCK MODE - OTP: 123456)');
      return;
    }

    if (!authKey) {
      logger.warn('MSG91 auth key not configured - OTP features disabled');
      return;
    }

    if (!templateId) {
      logger.warn('MSG91 template ID not configured - OTP features disabled');
      return;
    }

    this.isInit = true;
    logger.info('MSG91 OTP provider initialized');
  }

  isInitialized(): boolean {
    return this.isInit;
  }

  /**
   * Send OTP via MSG91
   */
  async sendOtp(
    params: SendOtpParams
  ): Promise<Result<SendOtpResponse, OtpError>> {
    if (!this.isInit && !this.useMockAuth) {
      logger.error('MSG91 not initialized - cannot send OTP');
      return err(Errors.SERVICE_UNAVAILABLE as OtpError);
    }

    const { authKey, templateId } = config.msg91;
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
        provider: 'msg91',
        verificationId: `reserved-test-${Date.now()}`,
      });
    }

    // Mock mode without credentials
    if (!authKey) {
      logger.info('MOCK MODE - OTP for testing', {
        phone: `+91${cleanPhone.slice(-4)}`,
        otp: '123456',
        env: config.server.nodeEnv,
      });
      return ok({
        provider: 'msg91',
        verificationId: `mock-${Date.now()}`,
      });
    }

    try {
      const response = await fetch(
        `https://control.msg91.com/api/v5/otp?template_id=${templateId}&mobile=91${cleanPhone}`,
        {
          method: 'POST',
          headers: {
            authkey: authKey,
            'Content-Type': 'application/json',
          },
        }
      );

      const data = (await response.json()) as {
        type: string;
        request_id?: string;
        message?: string;
      };

      if (data.type === 'success' && data.request_id) {
        logger.info('OTP sent successfully via MSG91', {
          phone: `***${cleanPhone.slice(-4)}`,
          requestId: data.request_id,
        });
        return ok({
          provider: 'msg91',
          verificationId: data.request_id,
        });
      }

      logger.error('MSG91 OTP send failed', { response: data });
      return err({
        code: 'OTP_SEND_FAILED',
        message: data.message || 'Failed to send OTP. Please try again.',
        httpStatus: 500,
        retryable: true,
      });
    } catch (error: any) {
      logger.error('MSG91 API error', {
        error: error.message || 'Unknown error',
      });

      return err({
        code: 'OTP_SEND_FAILED',
        message: 'Failed to send OTP. Please try again.',
        httpStatus: 500,
        retryable: true,
      });
    }
  }

  /**
   * Verify OTP via MSG91
   */
  async verifyOtp(
    params: VerifyOtpParams
  ): Promise<Result<VerifyOtpResponse, OtpError>> {
    if (!this.isInit && !this.useMockAuth) {
      return err(Errors.SERVICE_UNAVAILABLE as OtpError);
    }

    const { authKey } = config.msg91;
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

    // Mock mode without credentials
    if (!authKey) {
      const isValid = params.otp === '123456';
      logger.info('MOCK MODE - OTP verification', {
        phone: `+91${cleanPhone.slice(-4)}`,
        valid: isValid,
      });

      if (!isValid) {
        return err(Errors.OTP_INVALID as OtpError);
      }

      return ok({
        valid: true,
        verificationId: `mock-${Date.now()}`,
      });
    }

    try {
      const response = await fetch(
        `https://control.msg91.com/api/v5/otp/verify?mobile=91${cleanPhone}&otp=${params.otp}`,
        {
          method: 'POST',
          headers: {
            authkey: authKey,
            'Content-Type': 'application/json',
          },
        }
      );

      const data = (await response.json()) as {
        type: string;
        message?: string;
      };

      if (data.type === 'success') {
        logger.info('OTP verified successfully via MSG91', {
          phone: `***${cleanPhone.slice(-4)}`,
        });
        return ok({
          valid: true,
          verificationId: `msg91-${Date.now()}`,
        });
      }

      // Handle specific error cases
      if (data.type === 'error') {
        const message = data.message?.toLowerCase() || '';

        if (message.includes('otp expired') || message.includes('expired')) {
          return err(Errors.OTP_EXPIRED as OtpError);
        }

        if (
          message.includes('invalid') ||
          message.includes('wrong') ||
          message.includes('mismatch')
        ) {
          return err(Errors.OTP_INVALID as OtpError);
        }

        if (
          message.includes('limit') ||
          message.includes('exceeded') ||
          message.includes('too many')
        ) {
          return err({
            code: 'TOO_MANY_ATTEMPTS',
            message: 'Too many failed attempts. Please request a new OTP.',
            httpStatus: 429,
            retryable: false,
          });
        }
      }

      logger.warn('Invalid OTP entered', {
        phone: `***${cleanPhone.slice(-4)}`,
        response: data,
      });
      return err(Errors.OTP_INVALID as OtpError);
    } catch (error: any) {
      logger.error('MSG91 verify API error', {
        error: error.message || 'Unknown error',
      });

      return err({
        code: 'OTP_VERIFICATION_FAILED',
        message: 'Verification failed. Please try again.',
        httpStatus: 500,
        retryable: false,
      });
    }
  }

  /**
   * Resend OTP via MSG91 retry endpoint
   */
  async resendOtp(
    params: ResendOtpParams
  ): Promise<Result<SendOtpResponse, OtpError>> {
    if (!this.isInit && !this.useMockAuth) {
      return err(Errors.SERVICE_UNAVAILABLE as OtpError);
    }

    const { authKey } = config.msg91;
    const cleanPhone = params.phone.replace(/\D/g, '');
    const retryType = params.channel === 'voice' ? 'voice' : 'text';

    // Check reserved test numbers
    const isReservedTestNumber =
      this.reservedTestNumbers.length > 0 &&
      this.reservedTestNumbers.includes(cleanPhone);

    if (isReservedTestNumber || this.useMockAuth || !authKey) {
      logger.info('MOCK/TEST MODE - OTP resend', {
        phone: `+91${cleanPhone.slice(-4)}`,
      });
      return ok({
        provider: 'msg91',
        verificationId: `mock-resend-${Date.now()}`,
      });
    }

    try {
      const response = await fetch(
        `https://control.msg91.com/api/v5/otp/retry?mobile=91${cleanPhone}&retrytype=${retryType}`,
        {
          method: 'POST',
          headers: {
            authkey: authKey,
            'Content-Type': 'application/json',
          },
        }
      );

      const data = (await response.json()) as {
        type: string;
        request_id?: string;
        message?: string;
      };

      if (data.type === 'success') {
        logger.info('OTP resent successfully via MSG91', {
          phone: `***${cleanPhone.slice(-4)}`,
          retryType,
        });
        return ok({
          provider: 'msg91',
          verificationId: data.request_id || `msg91-resend-${Date.now()}`,
        });
      }

      logger.error('MSG91 OTP resend failed', { response: data });
      return err({
        code: 'OTP_SEND_FAILED',
        message: data.message || 'Failed to resend OTP. Please try again.',
        httpStatus: 500,
        retryable: true,
      });
    } catch (error: any) {
      logger.error('MSG91 resend API error', {
        error: error.message || 'Unknown error',
      });

      return err({
        code: 'OTP_SEND_FAILED',
        message: 'Failed to resend OTP. Please try again.',
        httpStatus: 500,
        retryable: true,
      });
    }
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

/// Shared OTP Verification Screen
///
/// Customizable OTP screen used by both merchant and user apps.
/// Parent handles BLoC integration and navigation.
class OtpScreenContent extends StatefulWidget {
  /// Phone number to display (formatted)
  final String phoneNumber;

  /// Called when OTP is completed and verify is pressed
  final void Function(String otp) onOtpSubmitted;

  /// Called when resend is requested
  final VoidCallback onResendRequested;

  /// Whether the form is currently verifying
  final bool isVerifying;

  /// Error text to display (if any)
  final String? errorMessage;

  const OtpScreenContent({
    super.key,
    required this.phoneNumber,
    required this.onOtpSubmitted,
    required this.onResendRequested,
    this.isVerifying = false,
    this.errorMessage,
  });

  @override
  State<OtpScreenContent> createState() => _OtpScreenContentState();
}

class _OtpScreenContentState extends State<OtpScreenContent> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _resendTimer;
  int _resendSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  void _onOtpCompleted(String otp) {
    if (otp.length == 6) {
      HapticFeedback.lightImpact();
      widget.onOtpSubmitted(otp);
    }
  }

  void _onResend() {
    if (!_canResend) return;

    HapticFeedback.lightImpact();
    _otpController.clear();
    _startResendTimer();
    widget.onResendRequested();
  }

  void _onVerify() {
    final otp = _otpController.text;
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter 6-digit OTP')),
      );
      return;
    }
    _onOtpCompleted(otp);
  }

  String _formatPhoneForDisplay(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+91 ${digits.substring(2, 7)} ${digits.substring(7)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Verify Phone Number'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),

                // Instructions
                Text(
                  'Enter the 6-digit code sent to',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatPhoneForDisplay(widget.phoneNumber),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // OTP Input
                _buildOtpInput(context),

                const SizedBox(height: 24),

                // Resend section
                _buildResendSection(context),

                const SizedBox(height: 48),

                // Verify button
                FilledButton(
                  onPressed: widget.isVerifying ? null : _onVerify,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: widget.isVerifying
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Verify'),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpInput(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final defaultPinTheme = PinTheme(
      width: 50,
      height: 56,
      textStyle: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: colorScheme.primary, width: 2),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: colorScheme.primary.withOpacity(0.1),
        border: Border.all(color: colorScheme.primary),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: colorScheme.error, width: 2),
      ),
    );

    return Pinput(
      controller: _otpController,
      focusNode: _focusNode,
      length: 6,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      submittedPinTheme: submittedPinTheme,
      errorPinTheme: errorPinTheme,
      autofillHints: const [AutofillHints.oneTimeCode],
      hapticFeedbackType: HapticFeedbackType.lightImpact,
      closeKeyboardWhenCompleted: true,
      onCompleted: _onOtpCompleted,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  Widget _buildResendSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_canResend) {
      return TextButton(
        onPressed: _onResend,
        child: Text(
          "Didn't receive code? Resend",
          style: TextStyle(color: colorScheme.primary),
        ),
      );
    }

    return Text(
      'Resend code in 0:${_resendSeconds.toString().padLeft(2, '0')}',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface.withOpacity(0.5),
      ),
      textAlign: TextAlign.center,
    );
  }
}

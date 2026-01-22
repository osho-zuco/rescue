import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../phone_input_field.dart';

/// Shared Login Screen - Phone Number Entry
///
/// Customizable login screen used by both merchant and user apps.
/// Parent handles BLoC integration and navigation.
class LoginScreenContent extends StatefulWidget {
  /// Icon to show in the top illustration
  final IconData illustrationIcon;

  /// Title text (e.g., "Welcome to Druto")
  final String title;

  /// Subtitle text (e.g., "Merchant Portal" or "Collect stamps...")
  final String subtitle;

  /// Description text (e.g., "Enter your phone number to continue")
  final String description;

  /// Called when user submits phone number
  final void Function(String phoneNumber) onPhoneSubmitted;

  /// Whether the form is currently loading
  final bool isLoading;

  /// Error text to display (if any)
  final String? errorMessage;

  const LoginScreenContent({
    super.key,
    required this.illustrationIcon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.onPhoneSubmitted,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<LoginScreenContent> createState() => _LoginScreenContentState();
}

class _LoginScreenContentState extends State<LoginScreenContent> {
  final _phoneController = TextEditingController();
  String? _errorText;
  bool _hasAutoSubmitted = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    super.dispose();
  }

  /// Auto-continue when 10 digits entered (WhatsApp/Uber style)
  void _onPhoneChanged() {
    final phone = _phoneController.text;

    if (phone.length < 10) {
      _hasAutoSubmitted = false;
      return;
    }

    if (phone.length == 10 && !_hasAutoSubmitted) {
      _hasAutoSubmitted = true;
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          FocusScope.of(context).unfocus();
          _onContinue();
        }
      });
    }
  }

  void _onContinue() {
    final phone = _phoneController.text.trim();

    if (!PhoneInputField.isValid(phone)) {
      setState(() {
        _errorText = 'Please enter a valid 10-digit phone number';
      });
      return;
    }

    setState(() => _errorText = null);
    HapticFeedback.lightImpact();

    final formattedPhone = PhoneInputField.formatWithCountryCode(phone);
    widget.onPhoneSubmitted(formattedPhone);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),

                // Illustration
                Center(
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.illustrationIcon,
                      size: 90,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Title
                Text(
                  widget.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  widget.subtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  widget.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Phone input
                PhoneInputField(
                  controller: _phoneController,
                  errorText: _errorText ?? widget.errorMessage,
                  onSubmitted: _onContinue,
                  autofocus: false,
                ),

                const SizedBox(height: 8),
                Text(
                  "We'll send you a one-time verification code via SMS",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Continue button
                FilledButton(
                  onPressed: widget.isLoading ? null : _onContinue,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: widget.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Continue'),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

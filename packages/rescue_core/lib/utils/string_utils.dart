/// String utility extensions
extension StringUtils on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize each word
  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Mask phone number (show last 4 digits)
  String maskPhone() {
    if (length < 4) return this;
    return '****${substring(length - 4)}';
  }

  /// Check if string is valid phone (10 digits)
  bool get isValidPhone => RegExp(r'^\d{10}$').hasMatch(this);

  /// Check if string is valid email
  bool get isValidEmail =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  /// Check if string is numeric
  bool get isNumeric => RegExp(r'^\d+$').hasMatch(this);

  /// Remove all whitespace
  String removeWhitespace() => replaceAll(RegExp(r'\s+'), '');

  /// Truncate with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Get initials (first letter of first 2 words)
  String get initials {
    final words = trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
}

/// Nullable string extensions
extension NullableStringUtils on String? {
  /// Check if null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Check if not null and not empty
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;

  /// Get value or default
  String orDefault([String defaultValue = '']) => this ?? defaultValue;
}

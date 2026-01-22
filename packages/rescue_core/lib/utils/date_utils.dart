import 'package:intl/intl.dart';

/// Date utility extensions
extension DateTimeUtils on DateTime {
  /// Format as "Jan 15, 2024"
  String get formatted => DateFormat('MMM d, yyyy').format(this);

  /// Format as "Jan 15"
  String get shortFormatted => DateFormat('MMM d').format(this);

  /// Format as "15 Jan 2024"
  String get dayMonthYear => DateFormat('d MMM yyyy').format(this);

  /// Format as "3:30 PM"
  String get timeFormatted => DateFormat('h:mm a').format(this);

  /// Format as "Jan 15, 2024 at 3:30 PM"
  String get dateTimeFormatted =>
      DateFormat('MMM d, yyyy \'at\' h:mm a').format(this);

  /// Format as "15/01/2024"
  String get slashFormatted => DateFormat('dd/MM/yyyy').format(this);

  /// Check if same day as another date
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Check if today
  bool get isToday => isSameDay(DateTime.now());

  /// Check if yesterday
  bool get isYesterday =>
      isSameDay(DateTime.now().subtract(const Duration(days: 1)));

  /// Check if tomorrow
  bool get isTomorrow =>
      isSameDay(DateTime.now().add(const Duration(days: 1)));

  /// Get relative time string ("2 hours ago", "in 3 days")
  String get relative {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays.abs() > 365) {
      final years = (difference.inDays / 365).abs().round();
      return difference.isNegative
          ? 'in $years ${years == 1 ? 'year' : 'years'}'
          : '$years ${years == 1 ? 'year' : 'years'} ago';
    }

    if (difference.inDays.abs() > 30) {
      final months = (difference.inDays / 30).abs().round();
      return difference.isNegative
          ? 'in $months ${months == 1 ? 'month' : 'months'}'
          : '$months ${months == 1 ? 'month' : 'months'} ago';
    }

    if (difference.inDays.abs() > 0) {
      final days = difference.inDays.abs();
      if (isToday) return 'Today';
      if (isYesterday) return 'Yesterday';
      if (isTomorrow) return 'Tomorrow';
      return difference.isNegative
          ? 'in $days ${days == 1 ? 'day' : 'days'}'
          : '$days ${days == 1 ? 'day' : 'days'} ago';
    }

    if (difference.inHours.abs() > 0) {
      final hours = difference.inHours.abs();
      return difference.isNegative
          ? 'in $hours ${hours == 1 ? 'hour' : 'hours'}'
          : '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }

    if (difference.inMinutes.abs() > 0) {
      final minutes = difference.inMinutes.abs();
      return difference.isNegative
          ? 'in $minutes ${minutes == 1 ? 'minute' : 'minutes'}'
          : '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    }

    return 'Just now';
  }

  /// Start of day (midnight)
  DateTime get startOfDay => DateTime(year, month, day);

  /// End of day (23:59:59.999)
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);
}
